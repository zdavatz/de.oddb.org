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
    class DimdiGalenicForm < Excel
      def import_row(row)
        abbr = cell(row, 0)
        description = capitalize_all(cell(row, 1))
        galenic_form = Drugs::GalenicForm.find_by_code(:value => abbr, 
                                                       :type => "galenic_form",
                                                       :country => 'DE')
        galenic_form ||= Drugs::GalenicForm.find_by_description(description)
        unless(galenic_form)
          galenic_form = Drugs::GalenicForm.new
          galenic_form.description.de = description
        end
        galenic_form.add_code(Util::Code.new("galenic_form", 
                                             abbr, 'DE'))
        galenic_form.save
        galenic_form
      end
    end
    class DimdiProduct < Excel
      def assign_substance_group(sub, groupname)
        if(sub.group.nil? \
           && (group = import_substance_group(groupname)))
          sub.group = group
          sub.save
        end
      end
      def import_row(row)
        name = capitalize_all(cell(row, 0))
        product = Drugs::Product.find_by_name(name)
        unless(product)
          product = Drugs::Product.new
          product.name.de = name
        end
        import_sequence(row, product)
        fpgroup = u(cell(row, 3).to_i.to_s)
        if(code = product.code(:festbetragsgruppe))
          code.value = fpgroup
        else
          code = Util::Code.new(:festbetragsgruppe, fpgroup, 'DE')
          product.add_code(code)
        end
        candidates = Drugs::Atc.search_by_name(cell(row, 2))
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
            package.add_code(Util::Code.new(:cid, pzn, 'DE'))
          end
        end
        if(level = cell(row, 12))
          date = cell(row, 13) || Date.today
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
        if(sequence.nil?)
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
        if((abbr = cell(row, 1)) \
           && (sub = Drugs::Substance.find_by_code(:value   => abbr, 
                       :type    => "substance", :country => "DE")))
          assign_substance_group(sub, groupname)
          subs.push(sub)
        end
        if(subs.empty?)
          subs = groupname.split('+').collect { |name| 
            assumed_name = name.strip[/^\S+/]
            unless(assumed_name.empty?)
              sub = Drugs::Substance.find_by_name(assumed_name)
              if(sub.nil?)
                sub = Drugs::Substance.new
                sub.name.de = assumed_name
                sub.save
              end
              assign_substance_group(sub, groupname)
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
    end
    class DimdiSubstance < Excel
      def import_row(row)
        abbr = cell(row, 0)
        name = capitalize_all(cell(row, 1))
        substance = Drugs::Substance.find_by_code(:value   => abbr,
                                                  :type    => "substance",
                                                  :country => "DE")
        substance ||= Drugs::Substance.find_by_name(name)
        unless(substance)
          substance = Drugs::Substance.new
          substance.name.de = name
          substance.add_code(Util::Code.new("substance", abbr, 'DE'))
        end
        substance.save
        substance
      end
    end
    class DimdiZuzahlungsBefreiung < Excel
      def import_row(row)
        ## for now: ignore packages that can not be linked to an 
        #  existing product by PZN
        pzn = u(cell(row, 1).to_i.to_s)
        if(package = Drugs::Package.find_by_code(:type => 'cid', 
                                                 :value => pzn, 
                                                 :country => 'DE'))
          if(code = package.code(:zuzahlungsbefreit))
            code.value = true
          else
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
          Business::Company.find_by_name(cname) or begin
            company = Business::Company.new
            company.name.de = cname
            company.save
            company
          end
        end
      end
      def import_substance(substance_name)
        if(substance_name)
          Drugs::Substance.find_by_name(substance_name) or begin
            substance = Drugs::Substance.new
            substance.name.de = substance_name
            substance.save
            substance
          end
        end
      end
    end
  end
end
