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
  DIMDI_PATH = "ftp://ftp.dimdi.de/pub/amg/"
  def Dimdi.current_date(url)
    if(match = /fb(\d\d)(\d\d)(\d\d)\.xls/.match(open(url).read))
      Date.new(2000 + match[3].to_i, match[2].to_i, match[1].to_i)
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
		warn e.message
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
  rescue StandardError
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
      atc_name = cell(row, 2)
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
      pzn = u(cell(row, 10).to_i.to_s)
      package = Drugs::Package.find_by_code(:type    => 'cid',
                                            :value   => pzn,
                                            :country => 'DE')
      name = capitalize_all(cell(row, 0))
      product = Drugs::Product.find_by_name(name)
      if(!package)
        ## new package and possibly new product
        import_product(row, product, name)
      elsif(!product)
        ## known package but unknown product
        rename_product(row, package, name)
      elsif(product != package.product)
        ## product-name has changed
        move_package(row, product, package, name)
      else
        ## update package-data
        update_package(row, package)
      end
    end
    def import_package(row, sequence, unitname)
      ## we don't expect any multipart packages here
      psize = cell(row, 6)
      package = Drugs::Package.new
      pzn = u(cell(row, 10).to_i.to_s)
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
      part.save
      package.add_part(part)
      package.sequence = sequence
      package.save
      update_package(row, package)
    end
    def import_product(row, product, name)
      if(product)
        @existing += 1
      else
        @created += 1
        product = Drugs::Product.new
        product.name.de = name
        product.save
      end
      import_sequence(row, product)
    end
    def import_price(package, type, amount)
      if(price = package.price(type, 'DE'))
        if(price != amount)
          price.amount = amount
        end
      else
        price = Util::Money.new(amount, type, 'DE')
        package.add_price(price)
      end
    end
    def import_sequence(row, product, package=nil)
      ## be simplistic here - the input file can not describe
      #  multiple compositions or active agents. Simply identify
      #  existing active agents by their substance and dose.
      sequence, composition, substance, dose = nil
      substances = import_substances(row)
      galform = import_galenic_form(row)
      if(dose = cell(row, 5))
        dose = Drugs::Dose.new(dose, 'mg')
      end
      sequence = product.sequences.find { |seq|
        doses = seq.doses
        seq.galenic_forms == [galform] \
          && seq.substances == substances \
          && (doses.empty? || doses.inject { |a, b| a + b } == dose)
      } 
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
          composition.add_active_agent(active_agent)
        }
        composition.galenic_form = galform
        if(factor = cell(row, 11))
          composition.equivalence_factor = factor
        end
        composition.save
        sequence.add_composition(composition)
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
      Drugs::GalenicForm.find_by_code(:value   => cell(row, 4),
                                      :type    => "galenic_form",
                                      :country => 'DE')
    end
    def import_substances(row)
      subs = []
      groupname = cell(row, 2)
      if(abbr = cell(row, 1))
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
        sprintf("Created    %5i new Products", @created),
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
      fpgroup = cell(row, 3)
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
      import_price(package, :public, cell(row, 7)) && modified = true
      import_price(package, :festbetrag, cell(row, 8)) && modified = true
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
        ass.name.synonyms.push('ASS').uniq!
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
  class ZuzahlungsBefreiung < Excel
    def initialize
      super
      @assigned_companies = 0
      @confirmed_pzns = {}
      @count = 0
      @created = 0
      @created_companies = 0
      @created_products = 0
      @created_sequences = 0
      @created_substances = 0
      @deleted = 0
      @existing = 0
      @existing_companies = 0
      @existing_substances = 0
    end
    def import_row(row)
      @count += 1
      package = import_package(row)
      @confirmed_pzns.store(package.code(:cid).value, true)
      if(code = package.code(:zuzahlungsbefreit))
        if(code.value)
          @existing += 1
        else
          @created += 1
        end
        code.value = true
      else
        @created += 1
        code = Util::Code.new(:zuzahlungsbefreit, true, 'DE')
        package.add_code(code)
      end
      sequence = package.sequence
      product = sequence.product
      atc_name = cell(row, 0)
      candidates = Drugs::Atc.search_by_exact_name(atc_name)
      if(candidates.size == 1)
        atc = candidates.first
        if(sequence.atc.nil? || \
           (sequence.atc != atc && atc.level >= sequence.atc.level))
          sequence.atc = atc
          sequence.save
        end
      end
      part = package.parts.first
      mnum, qnum = cell(row, 4).to_s.split('X')
      if(qnum.nil?)
        mnum, qnum = qnum, mnum
      end
      sunit = cell(row, 5)
      if(sunit == "ml")
        dose = Drugs::Dose.new(qnum, sunit)
        if(part.quantity != dose || part.size != mnum)
          part.quantity = dose
          part.size = mnum
          part.unit = nil
          part.save
        end
      else
        unit = Drugs::Unit.find_by_name(cell(row, 3))
        changed = false
        if(qnum && part.size != qnum)
          part.size = qnum
          changed = true
        end
        if(unit && part.unit != unit)
          part.unit = unit
          changed = true
        end
        part.save if changed
      end
      if((company = import_company(row)) && product.company != company)
        product.company = company
        product.save
      end
      import_active_agent(sequence, row, 8)
      import_active_agent(sequence, row, 11)
      import_active_agent(sequence, row, 14)
      package.save
    end 
    def import_active_agent(sequence, row, offset)
      name = cell(row, offset)
      sane = sanitize_substance_name(name) 
      composition = sequence.compositions.first
      dose = Drugs::Dose.new(cell(row, offset + 1), 
                             cell(row, offset + 2))
      ## check for slightly different names
      if(composition \
        && (agent = composition.active_agents.find { |act|
          act.substance.name.all.any? { |sub| 
            sane == sanitize_substance_name(sub) 
          }
        }))
        agent.dose = dose
        agent.save
        substance = agent.substance
        if(substance.name != name)
          substance.name.synonyms.push(name)
          substance.save
        end
      elsif(substance = import_substance(name))
        ## for now: don't expect multiple compositions
        if(composition.nil?)
          composition = Drugs::Composition.new
          sequence.add_composition(composition)
          sequence.save
        end
        candidate_names = [ name[/^\S+/], name[/^[^-]+/] ].uniq
        agent = nil
        if(agent = composition.active_agent(substance))
          agent.dose = dose
          agent.save
        elsif(candidate_names.any? { |name| 
          agent = composition.active_agent(name) } )
          previous = agent.chemical_equivalence
          if(previous && previous.substance == substance)
            previous.dose = dose
            previous.save
          else
            previous.delete if(previous)
            chemical = Drugs::ActiveAgent.new(substance, dose)
            chemical.save
            agent.chemical_equivalence = chemical
            agent.save
          end
        else
          agent = Drugs::ActiveAgent.new(substance, dose)
          composition.add_active_agent(agent)
          composition.save
        end
      end
    end
    def import_company(row)
      if(name = cell(row, 6))
        cname = company_name(name)
        company = Business::Company.find_by_name(cname)
        if(company)
          @existing_companies += 1
        else
          @created_companies += 1
          company = Business::Company.new
          company.name.de = cname
          company.save
        end
        company
      end
    end
    def import_galenic_form(row)
      Drugs::GalenicForm.find_by_code(:value   => cell(row, 3),
                                      :type    => "galenic_form",
                                      :country => 'DE')
    end
    def import_package(row)
      pzn = u(cell(row, 1).to_i.to_s)
      package = Drugs::Package.find_by_code(:type => 'cid', 
                                            :value => pzn, 
                                            :country => 'DE')
      if(package.nil?)
        package = Drugs::Package.new
        package.add_code(Util::Code.new(:cid, pzn, 'DE'))
        part = Drugs::Part.new
        part.package = package
        part.save
        product = import_product(package, row)
        package.sequence = import_sequence(product, package, row)
        # package.save is called at the end of import_row
      end
      if(amount = cell(row, 7))
        if(price = package.price(:public, 'DE'))
          if(price != amount)
            price.amount = amount
          end
        else
          price = Util::Money.new(amount, :public, 'DE')
          package.add_price(price)
        end
      end
      package
    end
    def import_product(package, row)
      name = capitalize_all(cell(row, 2))
      search = name.dup
      product = nil
      candidates = []
      until(product || search.empty? || candidates.size > 1)
        candidates = Drugs::Product.search_by_name(search)
        if(candidates.size == 1)
          product = candidates.first
          product.name.synonyms.push(name)
          product.save
        end
        search.sub!(/(\s|^)\S*$/, '')
      end
      if(product.nil?)
        @created_products += 1
        product = Drugs::Product.new
        product.name.de = name
        product.save
      end
      product
    end
    def import_sequence(product, package, row)
      substances = []
      doses = []
      [8, 11, 14].each { |idx| 
        if(name = cell(row, idx)) 
          substances.push(import_substance(name))
          doses.push(Drugs::Dose.new(cell(row, idx + 1), 
                                     cell(row, idx + 2)))
        end
      }.compact
      galform = import_galenic_form(row)
      sequence = product.sequences.find { |seq|
        doses = seq.doses
        seq.galenic_forms == [galform] \
          && seq.substances == substances \
          && (doses.empty? || doses.inject { |a, b| a + b } == dose)
      } 
      if(sequence.nil?)
        @created_sequences += 1
        sequence = Drugs::Sequence.new
        composition = Drugs::Composition.new
        substances.each_with_index { |sub, idx|
          act = Drugs::ActiveAgent.new(sub, doses.at(idx))
          composition.add_active_agent(act)
          act.save
        }
        composition.galenic_form = galform
        composition.save
        sequence.add_composition(composition)
        sequence.product = product
        sequence.save
      end
      sequence
    end
    def import_substance(substance_name)
      if(substance_name)
        substance = Drugs::Substance.find_by_name(substance_name)
        if(substance)
          @existing_substances += 1
        else
          @created_substances += 1
          substance = Drugs::Substance.new
          substance.name.de = substance_name
          substance.save
        end
        substance
      end
    end
    def postprocess
      Drugs::Package.search_by_code(:type => 'zuzahlungsbefreit', 
                                    :value => 'true', 
                                    :country => 'DE').each { |package|
        pzn = package.code(:cid).value
        unless(@confirmed_pzns.include?(pzn))
          @deleted += 1
          package.code(:zuzahlungsbefreit).value = false
          package.save
        end
      }
      Drugs::Product.all { |product|
        unless(product.company)
          keys = product.name.de.split
          key = keys.pop
          if(key == 'Comp')
            key = keys.pop
          end
          company = Business::Company.find_by_name(key)
          if(company.nil?)
            companies = Business::Company.search_by_name(key)
            if(companies.size == 1)
              company = companies.pop
            end
          end
          if(company)
            @assigned_companies += 1
            product.company = company
            product.save
          end
        end
      }
      Drugs::Composition.all { |composition|
        composition.active_agents.each { |agent|
          name = agent.substance.name.de
          if(other = composition.active_agents.find { |candidate|
            candidate.substance.name.de[0,name.length] == name })
            qty = other.dose.qty
            if(qty == qty.to_i && !other.chemical_equivalence)
              agent, other = other, agent
            end
            if(agent.chemical_equivalence)
              raise "multiple chemical equivalences" 
            end
            composition.remove_active_agent(other)
            agent.chemical_equivalence = other
            agent.save
            other.save
            composition.save
          end
        }
      }
    end
    def report
      [
        sprintf("Imported %3i FB-Entries on %s:", 
                @count, Date.today.strftime("%d.%m.%Y")),
        sprintf("Visited  %3i existing FB-Entries", @existing),
        sprintf("Visited  %3i existing Companies", 
                @existing_companies),
        sprintf("Visited  %3i existing Substances", 
                @existing_substances),
        sprintf("Created  %3i new FB-Entries", @created),
        sprintf("Created  %3i new Products", @created_products),
        sprintf("Created  %3i new Sequences", @created_sequences),
        sprintf("Created  %3i new Companies", @created_companies),
        sprintf("Created  %3i new Substances", @created_substances),
        sprintf("Assigned %3i Companies", @assigned_companies),
      ]
    end
    def sanitize_substance_name(str)
      str.to_s.downcase.gsub(/[^a-z]/, '')
    end
  end
end
  end
end
