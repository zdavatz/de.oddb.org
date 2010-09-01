#!/usr/bin/env ruby
# Import::Dimdi -- de.oddb.org -- 04.09.2006 -- hwyss@ywesee.com

require 'fileutils'
require 'oddb/business/company'
require 'oddb/config'
require 'oddb/import/excel'
require 'oddb/util/code'
require 'oddb/util/money'
require 'oddb/drugs/active_agent'
require 'oddb/drugs/atc'
require 'oddb/drugs/composition'
require 'oddb/drugs/galenic_form'
require 'oddb/drugs/galenic_group'
require 'oddb/drugs/package'
require 'oddb/drugs/part'
require 'oddb/drugs/product'
require 'oddb/drugs/sequence'
require 'oddb/drugs/substance'
require 'oddb/drugs/substance_group'
require 'oddb/drugs/unit'
require 'open-uri'

module ODDB
  module Import
module Dimdi
  DIMDI_PATH = "http://www.dimdi.de/dynamic/de/amg/fbag/downloadcenter/2010/3-quartal/"
  def Dimdi.current_date(url)
    if(match = /festbetraege-(\d{4})(\d{2})\.xls/.match(open(url).read))
      Date.new(match[1].to_i, match[2].to_i)
    end
  end
  def Dimdi.download(file, &block)
    url = File.join(DIMDI_PATH, file)
    xls_dir = File.join(ODDB.config.var, 'xls')
    FileUtils.mkdir_p(xls_dir)
    dest = File.join(xls_dir, file)
    unless(File.exist?(dest))
      open(url) { |remote| 
        block.call(remote)
        remote.rewind
        open(dest, 'w') { |local|
          local << remote.read
        }
      }
    end
  rescue StandardError => e
    ODDB.logger.error('Dimdi') { e.message }
  end
  def Dimdi.download_latest(url, today, &block)
    file = File.basename(url)
    xls_dir = File.join(ODDB.config.var, 'xls')
    FileUtils.mkdir_p(xls_dir)
    dest = File.join(xls_dir, file)
    archive = File.join(ODDB.config.var, 'xls', 
                sprintf("%s-%s", today.strftime("%Y.%m.%d"), file))
    content = open(url).read
    if(!File.exist?(dest) || content.size != File.size(dest))
      open(archive, 'w') { |local|
        local << content
      }
      open(archive, 'r', &block)
      open(dest, 'w') { |local|
        local << content
      }
    end
  rescue StandardError => error
    ODDB.logger.error('Dimdi') { error.message }
  end
  class GalenicForm < DatedExcel
    def initialize(date = Date.today)
      super
      @count = 0
      @created = 0
      @existing = 0
    end
    def import_row(row)
      @count += 1
      abbr = cell(row, 0)
      description = capitalize_all(cell(row, 1))
      galenic_form = Drugs::GalenicForm.find_by_code(:value => abbr, 
                                                     :type => "galenic_form",
                                                     :country => 'DE')
      galenic_form ||= Drugs::GalenicForm.find_by_description(description)
      if(galenic_form)
        @existing += 1
      else
        @created += 1
        galenic_form = Drugs::GalenicForm.new
        galenic_form.description.de = description
      end
      galenic_form.add_code(Util::Code.new("galenic_form", 
                                           abbr, 'DE', @date))
      galenic_form.save
      galenic_form
    end
    def postprocess
      {
        'Injektion/Infusion' \
                          => [ 'P', 'Fertigspritzen' ],
        'Tabletten'       => [ 'O', 'Tabletten', 'Filmtabletten', 
                               'Kapseln', 'Dragees', 'Lacktabletten' ],
        'Transdermale Systeme' \
                          => [ 'TD', 'Pflaster, transdermal' ],
        'Tropfen'         => [ 'P', 'Tropfen' ],
        'Retard-Tabletten'=> [ 'O', 'Retardtabletten', 
                               'Retardfilmtabletten', 'Retardkapseln',
                               'Retarddragees' ],
        'Salben'          => [ 'T', 'Creme', 'Gel', 'Lotion', 'Salbe' ],
        'Suppositorien'   => [ 'R', 'Suppositorien' ], 
        'Vaginal-Produkte'=> [ 'V', 'Vaginalcreme', 'Vaginalovula', 
                               'Vaginaltabletten', 
                               'Vaginalsuppositorien']
      }.each { |groupname, formnames|
        group = Drugs::GalenicGroup.find_by_name(groupname) \
          || Drugs::GalenicGroup.new(groupname)
        group.administration = formnames.shift
        group.save
        formnames.each { |name|
          if((form = Drugs::GalenicForm.find_by_description(name)) \
             && !form.group)
            form.group = group
            form.save
          end
        }
      }
    end
    def report
      [
        sprintf("Imported %3i Galenic Forms per %s:", 
                @count, @date.strftime("%d.%m.%Y")),
        sprintf("Visited  %3i existing", @existing),
        sprintf("Created  %3i new", @created),
      ]
    end
  end
  class Product < DatedExcel
    def initialize(date = Date.today)
      super
      @count = 0
      @created = 0
      @created_sequences = 0
      @created_substances = 0
      @deleted_sequences = 0
      @deleted_products = 0
      @existing = 0
      @existing_sequences = 0
      @reassigned_pzns = 0
      @renamed_products = 0
    end
    def assign_substance_group(sub, groupname)
      if(sub.group.nil? \
         && (group = import_substance_group(groupname)))
        sub.group = group
        sub.save
      end
    end
    def create_product name
      product = Drugs::Product.new
      product.name.de = name
      product.save
    end
    def delete_sequence(sequence)
      product = sequence.product
      if(product.sequences.size == 1)
        @deleted_products += 1
        product.delete
      else
        @deleted_sequences += 1
        sequence.delete
      end
      sequence
    end
    def import_atc(row, sequence)
      atc_name = cell(row, 10)
      substances = sequence.substances.uniq
      candidates = []
      if(substances.size == 1)
        substance = substances.first
        candidates = Drugs::Atc.search_by_exact_name(substance.to_s)
        if(candidates.empty?)
          candidates = Drugs::Atc.search_by_name(substance.to_s)
        end
      end
      if(candidates.size != 1)
        candidates = Drugs::Atc.search_by_exact_name(atc_name)
      end
      if(candidates.empty?)
        candidates = Drugs::Atc.search_by_name(atc_name)
      end
      if(candidates.size == 1)
        atc = candidates.first
        if(sequence.atc.nil? \
           || (sequence.atc != atc && atc.level >= sequence.atc.level))
          sequence.atc = atc
          sequence.save
        end
      end
    end
    def import_row(row)
      @package_date = cell(row, 13) || @date
      @count += 1
      pzn = u(cell(row, 0).to_i.to_s)
      package = Drugs::Package.find_by_code(:type    => 'cid',
                                            :value   => pzn,
                                            :country => 'DE')
      name = product_name(row)
      product = Drugs::Product.find_by_name(name)
      if !package
        ## new package and possibly new product
        import_product row, product, name
      elsif !package.product
        product ||= create_product name
        if package.sequence.nil?
          import_sequence row, product, package
        else
          seq = package.sequence
          seq.product = product
          seq.save
          update_package row, package
        end
      else
        ## update package-data
        update_package row, package
      end
    end
    def import_package(row, sequence, unitname)
      ## we don't expect any multipart packages here
      psize = cell(row, 2)
      package = Drugs::Package.new
      pzn = u(cell(row, 0).to_i.to_s)
      package.add_code(Util::Code.new(:cid, pzn, 'DE', @package_date))
      part = Drugs::Part.new
      part.size = psize
      if(unitname)
        unit = Drugs::Unit.find_by_name(unitname)
        if(unit.nil?)
          unit = Drugs::Unit.new
          unit.name.de = unitname
          unit.save
        end
        part.unit = unit
      end
      part.composition = sequence.compositions.first
      part.package = package
      part.save
      package.sequence = sequence
      package.save
      update_package(row, package)
    end
    def import_product(row, product, name)
      if(product)
        @existing += 1
      else
        @created += 1
        product = create_product name
      end
      import_sequence(row, product)
    end
    def import_price(package, type, amount)
      dotype = :"price_#{type}"
      # if this price has been edited manually we won't overwrite
      unless((data_origin = package.data_origin(dotype)) \
         && data_origin.to_s.include?('@'))
        if(price = package.price(type, 'DE'))
          if(price != amount)
            price.amount = amount
          end
        else
          price = Util::Money.new(amount, type, 'DE')
          package.add_price(price)
        end
        package.data_origins.store dotype, :dimdi
      end
    end
    def import_sequence(row, product, package=nil)
      ## be simplistic here - the input file can not describe
      #  multiple compositions or active agents. Simply identify
      #  existing active agents by their substance and dose.
      sequence, composition, substance, dose = nil
      substances = import_substances(row)
      galform = import_galenic_form(row)
      if(dose = cell(row, 8))
        dose = Drugs::Dose.new(dose, 'mg')
      end
      if product
        sequence = product.sequences.find { |seq|
          doses = seq.doses
          seq.galenic_forms == [galform] \
            && seq.substances == substances \
            && (doses.empty? || doses.inject { |a, b| a + b } == dose)
        } 
      end
      if(sequence)
        @existing_sequences += 1
      else
        @created_sequences += 1
        sequence = Drugs::Sequence.new
        composition = Drugs::Composition.new
        if(substances.size > 1)
          dose = nil
        end
        substances.each { |substance|
          active_agent = Drugs::ActiveAgent.new(substance, dose)
          active_agent.composition = composition
        }
        composition.galenic_form = galform
        if(factor = cell(row, 9))
          composition.equivalence_factor = factor
        end
        composition.sequence = sequence
        composition.save
        sequence.product = product
        sequence.save
      end
      import_atc(row, sequence)
      if(package)
        package.sequence = sequence
        package.save
        update_package(row, package)
      else
        unitname = nil
        if(galform)
          unitname = galform.description.de
        end
        import_package(row, sequence, unitname)
      end
    end
    def import_galenic_form(row)
      Drugs::GalenicForm.find_by_code(:value   => cell(row, 6),
                                      :type    => "galenic_form",
                                      :country => 'DE')
    end
    def import_substances(row)
      subs = []
      groupname = cell(row, 10)
      if(abbr = cell(row, 7))
        if(sub = Drugs::Substance.find_by_code(:value => abbr, 
                   :type => "substance", :country => "DE"))
          assign_substance_group(sub, groupname)
          subs.push(sub)
        else
          subs = Drugs::Substance.search_by_code(:value => abbr,
                   :type => "substance-combination", :country => 'DE')
        end
      end
      if(subs.empty?)
        names = groupname.split('+')
        subs = names.collect { |name| 
          assumed_name = name.strip[/^\S+/]
          unless(assumed_name.empty?)
            sub = Drugs::Substance.find_by_name(assumed_name)
            if(sub.nil?)
              @created_substances += 1
              sub = Drugs::Substance.new
              sub.name.de = assumed_name
              sub.save
            end
            if(names.size == 1)
              assign_substance_group(sub, groupname)
            end
            sub
          end
        }
      end
      subs.compact
    end
    def import_substance_group(groupname)
      groupname = groupname.to_s.strip
      if(groupname.length > 3)
        group = Drugs::SubstanceGroup.find_by_name(groupname)
        if(group.nil?)
          group = Drugs::SubstanceGroup.new
          group.name.de = groupname
          group.save
        end
        group
      end
    end
    def move_package(row, product, package, name)
      @existing += 1
      move_from = package.sequence
      move_to = product.sequences.find { |sequence|
        sequence.comparable?(move_from)
      }
      if(move_to)
        @existing_sequences += 1
        package.sequence = move_to
        package.save
        update_package(row, package)
        if(move_from.packages.empty?)
          delete_sequence(move_from)
        end
      elsif(move_from.packages.size == 1)
        @existing_sequences += 1
        move_sequence(product, move_from)
        update_package(row, package)
      else
        import_sequence(row, product, package)
      end
    end
    def move_sequence(product, sequence)
      move_from = sequence.product
      sequence.product = product
      sequence.save
      if(move_from.sequences.empty?)
        @deleted_products += 1
        move_from.delete
      end
    end
    def postprocess
      Drugs::Product.all { |product|
        sequences = product.sequences.dup
        sequences.each { |sequence|
          sequences.dup.each { |other|
            if(sequence != other && other.identical?(sequence))
              other.packages.each { |package|
                package.sequence = sequence
                package.save
              }
              sequences.delete other # should be safe because Array is ordered
              other.delete
            end
          }
        }
      }
    end
    def product_name(row)
      if data = cell(row, 1)
        capitalize_all(data.gsub(/[^A-Z\s]/, '').gsub(/\s+/, ' ')).strip
      end
    end
    def rename_product(row, package, name)
      @renamed_products += 1
      product = package.product
      product.name.de = name
      product.save
      update_package(row, package)
    end
    def report
      [
        sprintf("Imported   %5i Products per %s:", 
                @count, @date.strftime("%d.%m.%Y")),
        sprintf("Visited    %5i existing Products", @existing),
        sprintf("Visited    %5i existing Sequences", 
                @existing_sequences),
        sprintf("Ignored    %5i unknown Products", @created),
        sprintf("Created    %5i new Sequences", @created_sequences),
        sprintf("Created    %5i new Substances from Combinations",
                @created_substances),
        sprintf("Renamed    %5i Products", @renamed_products),
        sprintf("Reassigned %5i PZNs", @reassigned_pzns),
        sprintf("Deleted    %5i Products", @deleted_products),
        sprintf("Deleted    %5i Sequences", @deleted_sequences),
      ]
    end
    def update_package(row, package)
      modified = false
      fpgroup = cell(row, 11)
      unless(fpgroup.is_a?(String))
        fpgroup = u(fpgroup.to_i.to_s)
      end
      if(code = package.code(:festbetragsgruppe))
        if(code.value != fpgroup)
          modified = true
          code.value = fpgroup, @package_date
        end
      else
        modified = true
        package.add_code(Util::Code.new(:festbetragsgruppe, 
                                        fpgroup, 'DE', @package_date))
      end
      import_price(package, :public, cell(row, 3)) && modified = true
      if(efp = package._price_exfactory)
        import_price(package, :exfactory, efp.to_f) && modified = true
      end
      import_price(package, :festbetrag, cell(row, 4)) && modified = true
      if(level = cell(row, 12))
        if(code = package.code(:festbetragsstufe))
          if(code.value != level.to_i)
            modified = true
            code.value = level.to_i, @package_date
          end
        else
          modified = true
          package.add_code(Util::Code.new(:festbetragsstufe, level.to_i,
                                          'DE', @package_date))
        end
      end
      package.save if(modified)
    end
  end
  class Substance < DatedExcel
    def initialize(date = Date.today)
      super
      @combi_created = 0
      @combi_existing = 0
      @count = 0
      @created = 0
      @existing = 0
    end
    def import_row(row)
      @count += 1
      abbr = cell(row, 0)
      names = capitalize_all(cell(row, 1)).split('+')
      if(names.size == 1)
        import_substance(abbr, names.pop)
      else
        import_substances(abbr, names)
      end
    end
    def import_substance(abbr, name)
      substance = Drugs::Substance.find_by_code(:value => abbr,
                    :type => "substance", :country => "DE")
      substance ||= Drugs::Substance.find_by_name(name)
      unsaved = false
      if(substance)
        @existing += 1
      else
        @created += 1
        substance = Drugs::Substance.new
        substance.name.de = name
        unsaved = true
      end
      unless(substance.code('substance', 'DE'))
        substance.add_code(Util::Code.new("substance", abbr, 
                                          'DE', @date))
        unsaved = true
      end
      substance.save if(unsaved)
      substance
    end
    def import_substances(abbr, names)
      code = Util::Code.new('substance-combination', abbr, 
                            'DE', @date)
      names.collect { |name|
        substance = Drugs::Substance.find_by_name(name)
        if(substance)
          @combi_existing += 1
        else
          @combi_created += 1
          substance = Drugs::Substance.new
          substance.name.de = name
        end
        substance.add_code(code)
        substance.save
        substance
      }
    end
    def postprocess
      ## a special case that probably fits best here:
      if((ass = Drugs::Substance.find_by_name('ASS')) \
         && ass.name.de == 'ASS')
        ass.name.add_synonym('ASS')
        ass.name.de = 'Acetylsalicylsäure'
        ass.save
      end
    end
    def report
      [
        sprintf("Imported %3i Substances per %s:", 
                @count, @date.strftime("%d.%m.%Y")),
        sprintf("Visited  %3i existing", @existing),
        sprintf("Visited  %3i existing in Combinations", 
                @combi_existing),
        sprintf("Created  %3i new", @created),
        sprintf("Created  %3i new from Combinations", @combi_created),
      ]
    end
  end
end
  end
end
