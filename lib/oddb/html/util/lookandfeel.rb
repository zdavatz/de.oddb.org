#!/usr/bin/env ruby
# Html::Util::Lookandfeel -- de.oddb.org -- 27.10.2006 -- hwyss@ywesee.com

require 'sbsm/lookandfeel'

module ODDB
  module Html
    module Util
class Lookandfeel < SBSM::Lookandfeel
  DICTIONARIES = {
    "de"  =>  {
      :drugs                => 'Medikamente',
      :empty_packages       => <<-EOS,
Ihr Such-Stichwort hat zu keinem Suchergebnis geführt. Bitte
überprüfen Sie die Schreibweise und versuchen Sie es noch
einmal.
    EOS
      :festbetragsstufe     => ' (Gesetzestext)',
      :festbetragsstufe_url => 'http://www.sozialgesetzbuch-bundessozialhilfegesetz.de/buch/sgbv/35.html',
      :festbetragsstufe_1   => 'Arzneimittel mit denselben Wirkstoffen',
      :festbetragsstufe_2   => 'Arzneimittel mit pharmakologisch-therapeutisch vergleichbaren Wirkstoffen, insbesondere mit chemisch verwandten Stoffen',
      :festbetragsstufe_3   => 'Arzneimittel mit therapeutisch vergleichbarer Wirkung, insbesondere Arzneimittelkombinationen',
      :home                 => 'Home',
      :html_title           => 'ODDB',
      :lgpl_license         => 'LGPL',
      :logo                 => 'de.oddb.org - peer reviewed open drug database',
      :oddb_version         => 'Commit-ID',
      :pzn0                 => 'Pharmazentralnummer: ',
      :pzn1                 => '',
      :query_info           => 'Bitte HIER Such-Stichwort eingeben',
      :reset                => 'Zurücksetzen',
      :search               => 'Suchen',
      :th_atc               => 'ATC-Code',
      :th_company           => 'Hersteller',
      :th_doses             => 'Stärke',
      :th_festbetrag        => 'FB',
      :th_festbetragsstufe  => 'FB-Stufe',
      :th_price_difference  => 'ABS-Differenz',
      :th_price_public      => 'PP',
      :th_product           => 'Präparat',
      :th_size              => 'Packungsgrösse',
      :th_zuzahlungsbefreit => 'Zuzahlungsbefreit',
      :tt_atc               => <<-EOS,
The field of drug utilization research has attracted increasing
interest since its infancy in the 1960s. At a symposium in Oslo 
in 1969 entitled The Consumption of Drugs, it was agreed that an
internationally accepted classification system for drug consumption
studies was needed. At the same symposium the Drug Utilization Research
Group (DURG) was established and tasked with the development of
internationally applicable methods for drug utilization research...
      EOS
      :tt_festbetrag        => <<-EOS,
Festbetrag: DIMDI hat die Aufgabe, die von den Spitzenverbänden der
Krankenkassen erstellten und veröffentlichten Übersichten über
sämtliche Festbeträge und die betroffenen Arzneimittel im Internet
abruffähig zu veröffentlichen...
      EOS
      :tt_festbetragsstufe  => <<-EOS,
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
      :tt_price_difference  => 'Absolute Differenz zwischen Preis und Festbetrag',
      :tt_price_public      => 'Preis: Apothekenverkaufspreis inkl. MwSt. in Euro',
      :tt_zuzahlungsbefreit => <<-EOS,
Im Jahr 2005 lagen die Ausgaben für Arzneimittel über den Aufwendungen
für die ambulante ärztliche Behandlung. In Deutschland werden noch
immer zu viele teure Medikamente verordnet, obwohl es gleichwertige,
deutlich preiswertere Alternativen gibt. Das Arzneimittelversorgungs-
Wirtschaftlichkeitsgesetz (AVWG), das am 1. Mai 2006 in Kraft getreten
ist, schafft Anreize für mehr Wirtschaftlichkeit bei der Verordnung von
Arzneimitteln...
      EOS
      :yes                  => 'Ja',
      :ywesee               => 'ywesee.com',
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
end
    end
  end
end
