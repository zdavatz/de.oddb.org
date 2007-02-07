#!/usr/bin/env ruby
# Import::Dimdi -- de.oddb.org -- 04.09.2006 -- hwyss@ywesee.com

require 'oddb/business/company'
require 'oddb/import/excel'
require 'oddb/util/code'
require 'oddb/util/money'
require 'oddb/drugs/active_agent'
require 'oddb/drugs/atc'
require 'oddb/drugs/composition'
require 'oddb/drugs/galenic_form'
require 'oddb/drugs/package'
require 'oddb/drugs/part'
require 'oddb/drugs/product'
require 'oddb/drugs/sequence'
require 'oddb/drugs/substance'
require 'oddb/drugs/substance_group'
require 'oddb/drugs/unit'

module ODDB
  module Import
    class DatedExcel < Excel
      def initialize(date = Date.today)
        super()
        @date = date
      end
    end
    class DimdiGalenicForm < DatedExcel
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
      def report
        [
          sprintf("Imported %3i Galenic Forms per %s:", 
                  @count, @date.strftime("%d.%m.%Y")),
          sprintf("Visited  %3i existing", @existing),
          sprintf("Created  %3i new", @created),
        ]
      end
    end
    class DimdiProduct < DatedExcel
      def initialize(date = Date.today)
        super
        @count = 0
        @created = 0
        @created_sequences = 0
        @created_substances = 0
        @existing = 0
        @existing_sequences = 0
      end
      def assign_substance_group(sub, groupname)
        if(sub.group.nil? \
           && (group = import_substance_group(groupname)))
          sub.group = group
          sub.save
        end
      end
      def import_row(row)
        @count += 1
        name = capitalize_all(cell(row, 0))
        product = Drugs::Product.find_by_name(name)
        if(product)
          @existing += 1
        else
          @created += 1
          product = Drugs::Product.new
          product.name.de = name
        end
        import_sequence(row, product)
        fpgroup = u(cell(row, 3).to_i.to_s)
        if(code = product.code(:festbetragsgruppe))
          code.value = fpgroup
        else
          code = Util::Code.new(:festbetragsgruppe, fpgroup, 
                                'DE', @date)
          product.add_code(code)
        end
        atc_name = cell(row, 2)
        candidates = Drugs::Atc.search_by_exact_name(atc_name)
        if(candidates.empty?)
          candidates = Drugs::Atc.search_by_name(atc_name)
        end
        if(candidates.size == 1)
          product.atc = candidates.first
        end
        product.save
      end
      def import_package(row, sequence, unitname)
        ## we don't expect any multipart packages here
        psize = cell(row, 6)
        package = sequence.packages.find { |pac| 
          pac.size == psize
        }
        if(package.nil?)
          package = Drugs::Package.new
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
        end
        import_price(package, :public, cell(row, 7))
        import_price(package, :festbetrag, cell(row, 8))
        if(pzn = cell(row, 10))
          pzn = u(pzn.to_i.to_s)
          if(code = package.code(:cid))
            code.value = pzn
          else
            package.add_code(Util::Code.new(:cid, pzn, 'DE', @date))
          end
        end
        if(level = cell(row, 12))
          date = cell(row, 13) || @date
          if(code = package.code(:festbetragsstufe))
            code.value = level.to_i, date
          else
            package.add_code(Util::Code.new(:festbetragsstufe,
                                            level.to_i, 'DE', date))
          end
        end
        package.save
      end
      def import_price(package, type, amount)
        if(price = package.price(type, 'DE'))
          price.amount = amount
        else
          price = Util::Money.new(amount, type, 'DE')
          package.add_price(price)
        end
      end
      def import_sequence(row, product)
        ## be simplistic here - the input file can not describe
        #  multiple compositions or active agents. Simply identify
        #  existing active agents by their substance and dose.
        sequence, composition, substance, dose = nil
        substances = import_substances(row)
        if(dose = cell(row, 5))
          dose = Drugs::Dose.new(dose, 'mg')
        end
        sequence = product.sequences.find { |seq|
          doses = seq.doses
          seq.substances == substances \
            && (doses.empty? || doses.inject { |a, b| a + b } == dose)
        } 
        if(sequence)
          @existing_sequences += 1
        else
          @created_sequences += 1
          sequence = Drugs::Sequence.new
          composition = Drugs::Composition.new
          sequence.add_composition(composition)
          sequence.product = product
          sequence.save
        end
        composition = sequence.compositions.first
        if(substances.size > 1)
          dose = nil
        end
        substances.each { |substance|
          unless(composition.include?(substance))
            active_agent = Drugs::ActiveAgent.new(substance, dose)
            composition.add_active_agent(active_agent)
            composition.save
          end
        }
        unitname = nil
        if(galform = import_galenic_form(row))
          unitname = galform.description.de
          composition.galenic_form = galform
        end
        if(factor = cell(row, 11))
          composition.equivalence_factor = factor
        end
        composition.save
        import_package(row, sequence, unitname)
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
      def report
        [
          sprintf("Imported %3i Products per %s:", 
                  @count, @date.strftime("%d.%m.%Y")),
          sprintf("Visited  %3i existing Products", @existing),
          sprintf("Visited  %3i existing Sequences", 
                  @existing_sequences),
          sprintf("Created  %3i new Products", @created),
          sprintf("Created  %3i new Sequences", @created_sequences),
          sprintf("Created  %3i new Substances from Combinations",
                  @created_substances),
        ]
      end
    end
    class DimdiSubstance < DatedExcel
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
    class DimdiZuzahlungsBefreiung < Excel
      def initialize
        super
        @assigned_companies = 0
        @confirmed_pzns = {}
        @count = 0
        @created = 0
        @created_companies = 0
        @created_substances = 0
        @deleted = 0
        @existing = 0
        @existing_companies = 0
        @existing_substances = 0
      end
      def import_row(row)
        @count += 1
        ## for now: ignore packages that can not be linked to an 
        #  existing product by PZN
        pzn = u(cell(row, 1).to_i.to_s)
        if(package = Drugs::Package.find_by_code(:type => 'cid', 
                                                 :value => pzn, 
                                                 :country => 'DE'))
          @confirmed_pzns.store(package.code(:pzn), true)
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
          if(atc = Drugs::Atc.find_by_name(cell(row, 0)))
            product.atc = atc
            product.save
          end
          part = package.parts.first
          mnum, qnum = cell(row, 4).to_s.split('X')
          if(qnum.nil?)
            mnum, qnum = qnum, mnum
          end
          sunit = cell(row, 5)
          if(sunit == "ml")
            part.quantity = Drugs::Dose.new(qnum, sunit)
            part.size = mnum
            part.unit = nil
          end
          if(company = import_company(row))
            product.company = company
            product.save
          end
          import_active_agent(sequence, row, 8)
          import_active_agent(sequence, row, 11)
          import_active_agent(sequence, row, 14)
          package.save
        end
      end
      def import_active_agent(sequence, row, offset)
        name = cell(row, offset)
        if(substance = import_substance(name))
          ## for now: don't expect multiple compositions
          composition = sequence.compositions.first
          if(composition.nil?)
            composition = Drugs::Composition.new
            sequence.add_composition(composition)
            sequence.save
          end
          dose = Drugs::Dose.new(cell(row, offset + 1), 
                                 cell(row, offset + 2))
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
        if(cname = cell(row, 6))
          cname = capitalize_all(cname)
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
          pzn = package.code(:pzn)
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
          sprintf("Created  %3i new Companies", @created_companies),
          sprintf("Created  %3i new Substances", @created_substances),
          sprintf("Assigned %3i Companies", @assigned_companies),
        ]
      end
    end
  end
end
