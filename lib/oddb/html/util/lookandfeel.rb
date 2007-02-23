#!/usr/bin/env ruby
# Html::Util::Lookandfeel -- de.oddb.org -- 27.10.2006 -- hwyss@ywesee.com

require 'sbsm/lookandfeel'
require 'sbsm/lookandfeelfactory'
require 'sbsm/lookandfeelwrapper'

module ODDB
  module Html
    module Util
class Lookandfeel < SBSM::Lookandfeel
  DICTIONARIES = {
    "de" =>  {
      :active_agents0           => '',
      :active_agents1           => ' Wirkstoffe',
      :atc                      => 'ATC-Code',
      :breadcrumb_divider       => '&nbsp;&ndash;&nbsp;',
      :choose_range             => 'Bitte wählen Sie den anzuzeigenden Bereich',
      :code_festbetragsgruppe   => 'Festbetragsgruppe',
      :code_festbetragsstufe    => 'Festbetragsstufe',
      :code_pzn                 => 'Pharmazentralnummer',
      :code_zuzahlungsbefreit   => 'Zuzahlungsbefreit',
      :company                  => 'Zulassungsinhaber',
      :compare                  => 'Preisvergleich',
      :compare_remote           => 'Preisvergleich',
      :comparison_for0          => 'Preisvergleich für ',
      :comparison_for1          => '',
      :contact                  => 'Kontakt',
      :drugs                    => 'Medikamente',
      :drugs_atc_codes          => "ATC-Codes, DDD's:",
      :drugs_copay_free         => 'Zuzahlungsbefreite Arzneimittel:',
      :drugs_fixprices          => 'Arzneimittelfestbeträge:',
      :e_query_short            => 'Ihr Such-Stichwort ergibt ein sehr grosses Resultat. Bitte verwenden Sie mindestens 3 Buchstaben.',
      :empty_comparison         => <<-EOS,
In unserer Datenbank wurden leider keine Produkte gefunden, 
die mit diesem Produkt verglichen werden können.
      EOS
      #
      :empty_packages           => <<-EOS,
Ihr Such-Stichwort hat zu keinem Suchergebnis geführt. Bitte
überprüfen Sie die Schreibweise und versuchen Sie es noch
einmal.
      EOS
      :equivalence_factor       => 'Wirkstärkenäquivalenzfaktor (waef)',
      :explain_compare          => 'Für einen Preisvergleich klicken Sie bitte auf den Medikamentennamen.', 
      :explain_currency_convert => 'Wechselkurs (1 EUR in CHF)',
      :explain_remote           => 'Rot = CH - Produkte', 
      :explain_zuzahlungsbefreit=> 'Gelb = Zuzahlungsbefreit', 
      :explain_search           => <<-EOS,
Vergleichen Sie einfach und schnell Medikamentenpreise.
Suchen Sie nach Medikamentname oder Wirkstoff.
      EOS
      :festbetragsstufe         => ' (Gesetzestext)',
      :festbetragsstufe_url     => 'http://www.sozialgesetzbuch-bundessozialhilfegesetz.de/buch/sgbv/35.html',
      :festbetragsstufe_1       => 'Arzneimittel mit denselben Wirkstoffen',
      :festbetragsstufe_2       => 'Arzneimittel mit pharmakologisch-therapeutisch vergleichbaren Wirkstoffen, insbesondere mit chemisch verwandten Stoffen',
      :festbetragsstufe_3       => 'Arzneimittel mit therapeutisch vergleichbarer Wirkung, insbesondere Arzneimittelkombinationen',
      :google                   => 'G',
      :google0                  => 'Google-Suche nach ',
      :google1                  => '',
      :home                     => 'Home',
      :html_title               => 'ODDB',
      :lgpl_license             => 'LGPL',
      :logo                     => 'de.oddb.org - peer reviewed open drug database',
      :name                     => 'Name',
      :no                       => 'Nein',
      :no_active_agents         => 'Keine Wirkstoffe in der DB',
      :oddb_version             => 'Commit-ID',
      :package                  => 'Details',
      :package_and_substances   => 'Packungsgrösse und Wirkstoffe',
      :parts                    => 'Teilpackungen',
      :price_festbetrag         => 'Festbetrag',
      :price_public             => 'Apothekenverkaufspreis',
      :products                 => 'Arzneimittel A-Z',
      :pzn0                     => 'Pharmazentralnummer: ',
      :pzn1                     => '',
      :query_info               => 'Bitte HIER Such-Stichwort eingeben',
      :reset                    => 'Zurücksetzen',
      :result                   => 'Suchresultat',
      :sb_digg                  => 'Digg',
      :sb_delicious             => 'Bookmark',
      :sb_simpy                 => 'Simpy',
      :sb_stumble               => 'Stumble',
      :search                   => 'Suchen',
      :th_active_agents         => 'Wirkstoff',
      :th_atc                   => 'ATC-Code',
      :th_code_festbetragsstufe => 'FB-Stufe',
      :th_code_zuzahlungsbefreit=> 'Zuzahlungsbefreit',
      :th_company               => 'Hersteller',
      :th_difference            => '%',
      :th_doses                 => 'Stärke',
      :th_price_difference      => 'ABS-Differenz',
      :th_price_festbetrag      => 'FB',
      :th_price_public          => 'AVP',
      :th_product               => 'Präparat',
      :th_size                  => 'Packungsgrösse',
      :title_found0             => 'Suchergebnis für "',
      :title_found1             => '", Total ',
      :title_found2             => ' Präparate',
      :tt_atc                   => <<-EOS,
The field of drug utilization research has attracted increasing
interest since its infancy in the 1960s. At a symposium in Oslo 
in 1969 entitled The Consumption of Drugs, it was agreed that an
internationally accepted classification system for drug consumption
studies was needed. At the same symposium the Drug Utilization Research
Group (DURG) was established and tasked with the development of
internationally applicable methods for drug utilization research...
      EOS
      # rcov needs a comment between two here-documents
      :tt_code_festbetragsstufe => <<-EOS,
Gruppen "vergleichbarer" Arzneimittel können nach unterschiedlichen
Kriterien gebildet werden, deshalb werden drei Stufen der Vergleich-
barkeit unterschieden: Festbetragsgruppen der Stufe 1 werden aus
Arzneimitteln mit denselben Wirkstoffen gebildet. Festbetragsgruppen
der Stufe 2 werden aus Arzneimitteln gebildet, deren Wirkstoffe
pharmakologisch, insbesondere chemisch, und dabei gleichzeitig auch
hinsichtlich ihrer therapeutischen Wirkung vergleichbar sind.
Festbetragsgruppen der Stufe 3 werden aus Arzneimitteln gebildet, 
die nicht hinsichtlich ihrer Wirkstoffe, aber hinsichtlich ihrer
therapeutischen Wirkung vergleichbar sind...
      EOS
      # rcov needs a comment between two here-documents
      :tt_code_zuzahlungsbefreit     => <<-EOS,
Zuzahlungsbefreite Arzneimittel:

Die Spitzenverbände der Krankenkassen haben am 11.05.2006 gemeinsam und
einheitlich für bestimmte zu Lasten ihrer Krankenkassen abgegebene
Arzneimittel Zuzahlungsbefreiungsgrenzen festgelegt.

Bei der Verordnung von Arzneimitteln, deren Apothekenverkaufspreise
inkl. MwSt. den Wert der jeweiligen Zuzahlungsbefreiungrenze nicht
überschreiten, sind Versicherte ab dem 1. Juli 2006 von der
gesetzlichen Zuzahlung nach § 31 Abs. 3 Satz 1 SGB V befreit.

Quelle: 
      EOS
      :tt_company               => 'Der Hersteller oder Zulassungsinhaber des Produkts',
      :tt_active_agents         => 'Die Stärke bezieht sich auf Darreichungsform-Einheit (Tablette, Zäpfchen, Sirup, etc). Siehe auch: ',
      :tt_active_agents_link    => 'Darreichungsformen',
      :tt_price_festbetrag      => <<-EOS,
Festbetrag: DIMDI hat die Aufgabe, die von den Spitzenverbänden der
Krankenkassen erstellten und veröffentlichten Übersichten über
sämtliche Festbeträge und die betroffenen Arzneimittel im Internet
abruffähig zu veröffentlichen...
      EOS
      :tt_price_difference      => 'Absolute Differenz zwischen Preis und Festbetrag',
      :tt_price_public          => 'Preis: Apothekenverkaufspreis inkl. MwSt. in Euro',
      :tt_product               => 'Präparat ist der Handelsname des Medikaments',
      :welcome_drugs            => <<-EOS,
Willkommen bei de.oddb.org, dem
aktuellsten Medikamenten-Portal Deutschlands.
** Herkunftsdeklaration der Daten **
      EOS
      :welcome_drugs_link       => 'Herkunftsdeklaration',
      :yes                      => 'Ja',
      :ywesee                   => 'ywesee.com',
    }
  }
  RESOURCES = {
    :logo => 'logo.gif', 
    :css  => 'oddb.css',
  }
  def base_url
    [@session.http_protocol + ':/', @session.server_name,
      @language, @session.zone].compact.join("/")
  end
  def legend_components
    { [0,0] => 'explain_zuzahlungsbefreit' }
  end
  def price_factor
    1.0
  end
  def result_components
    {
      [0,0] => :product,
      [1,0] => :active_agents,
      [2,0] => :size, 
      [3,0] => :price_public,
      [4,0] => :price_festbetrag,
      [5,0] => :price_difference,
      [6,0] => :code_festbetragsstufe,
      [7,0] => :code_zuzahlungsbefreit,
      [8,0] => :atc,
      [9,0] => :company,
      [10,0]=> :google,
    }
  end
end
class LookandfeelWrapper < SBSM::LookandfeelWrapper
  def base_url
    [@session.http_protocol + ':/', @session.server_name,
      @language, @session.zone].compact.join("/")
  end
end
class LookandfeelMeineMedikamente < LookandfeelWrapper
  ENABLED = [
    # Features:
    :remote_databases,
    # Navigation-Links:
    :contact, :home, :products,
  ]
  def legend_components
    { 
      [0,0] => 'explain_remote',
      [0,1] => 'explain_zuzahlungsbefreit', 
      [0,2] => :explain_currency_conversion,
    }
  end
  def price_factor
    107.6 / 119.0
  end
  def result_components
    {
      [0,0] => :product,
      [1,0] => :active_agents,
      [2,0] => :size, 
      [3,0] => :price_public,
      [4,0] => :atc,
      [5,0] => :company,
      [6,0] => :google,
    }
  end
end
class LookandfeelFactory < SBSM::LookandfeelFactory
  BASE = Lookandfeel
  WRAPPERS = {
    'mm' => [ LookandfeelMeineMedikamente ],
  }
end
    end
  end
end
