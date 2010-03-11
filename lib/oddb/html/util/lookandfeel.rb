#!/usr/bin/env ruby
# Html::Util::Lookandfeel -- de.oddb.org -- 27.10.2006 -- hwyss@ywesee.com

require 'sbsm/lookandfeel'
require 'sbsm/lookandfeelfactory'
require 'sbsm/lookandfeelwrapper'
require 'turing'
require 'fileutils'

module ODDB
  module Html
    module Util
class Lookandfeel < SBSM::Lookandfeel
  @@turing_files = {}
  @@turing_finalizer = proc { |id|
    if file = @@turing_files.delete(id)
      path = File.join(ODDB.config.var, 'captcha', file)
      File.delete(path) if File.exist?(path)
    end
  }
  Thread.new {
    FileUtils.rm Dir.glob(File.join(ODDB.config.var, 'captcha', '*'))
  }
  DICTIONARIES = {
    "de" =>  {
      :active_agents0             => '',
      :active_agents1             => ' Wirkstoffe',
      :address                    => 'Strasse/Nr.',
      :administration             => 'Verabreichungsform',
      :administration_O           => 'Oral',
      :administration_P           => 'Parenteral',
      :administration_R           => 'Rektal',
      :atc                        => 'ATC-Code',
      :atc_assign                 => 'ATC zuweisen',
      :atc_browser                => 'ATC-Browser',
      :atc_name                   => 'ATC-Name',
      :atc_unknown                => 'ATC-Code nicht bekannt',
      :ba_doctor                  => 'Arzt',
      :ba_health                  => 'Gesundheitsdienstleister',
      :ba_hospital                => 'Spital',
      :ba_info                    => 'Medi-Information',
      :ba_insurance               => 'Krankenkasse',
      :ba_pharma                  => 'Pharmaunternehmen',
      :breadcrumb_divider         => '&nbsp;&ndash;&nbsp;',
      :business_area              => 'Geschäftsbereich',
      :captcha                    => 'Was steht im Bild unten?',
      :chapter_active_agents      => 'Wirkstoffe', 
      :chapter_additional_information => 'Zusätzliche Angaben', 
      :chapter_application        => 'Anwendung', 
      :chapter_bioavailability    => 'Bioverfügbarkeit', 
      :chapter_clinical           => 'Klinische Angaben', 
      :chapter_company            => 'Zulassungsinhaber', 
      :chapter_composition        => 'Zusammensetzung', 
      :chapter_counterindications => 'Gegenanzeigen', 
      :chapter_date               => 'Stand der Information', 
      :chapter_default            => 'Einleitung',
      :chapter_disposal           => 'Beseitigung', 
      :chapter_dosage             => 'Dosierung', 
      :chapter_driving_ability    => 'Verkehrstüchtigkeit', 
      :chapter_emergency          => 'Verhalten im Notfall', 
      :chapter_excipients         => 'Sonstige Bestandteile', 
      :chapter_fachinfo           => 'Vollständige Fachinformation', 
      :chapter_galenic_form       => 'Darreichungsform', 
      :chapter_incompatibilities  => 'Inkompabilitäten', 
      :chapter_indications        => 'Anwendungsgebiete', 
      :chapter_interactions       => 'Wechselwirkungen', 
      :chapter_name               => 'Bezeichnung', 
      :chapter_overdose           => 'Überdosierung', 
      :chapter_other_advice       => 'Sonstige Hinweise', 
      :chapter_packaging          => 'Handelsformen', 
      :chapter_patinfo            => 'Vollständige Gebrauchsinformation', 
      :chapter_personal           => 'Zusammenfassung',
      :chapter_pharmaceutic       => 'Pharmazeutische Angaben', 
      :chapter_pharmacodynamics   => 'Pharmakodynamik', 
      :chapter_pharmacokinetics   => 'Pharmakokinetik', 
      :chapter_pharmacology       => 'Pharmakologie', 
      :chapter_precautions        => 'Vorsichtsmassnahmen', 
      :chapter_preclinicals       => 'Präklinische Daten', 
      :chapter_pregnancy          => 'Schwangerschaft / Stillzeit', 
      :chapter_producer           => 'Hersteller', 
      :chapter_registration       => 'Zulassungsnummern', 
      :chapter_registration_date  => 'Zulassungsdatum', 
      :chapter_sale_limitation    => 'Verkaufsabgrenzung', 
      :chapter_shelf_life         => 'Haltbarkeit', 
      :chapter_storage            => 'Aufbewahrung', 
      :chapter_substance_group    => 'Stoffgruppe', 
      :chapter_toxicology         => 'Toxikologie', 
      :chapter_unwanted_effects   => 'Nebenwirkungen', 
      :checkout                   => 'Bezahlen',
      :company_name               => 'Firmenname',
      :choose_range               => 'Bitte wählen Sie den anzuzeigenden Bereich',
      :ch_sl                      => 'SL',
      :ch_sl_entry                => 'Spezialitätenliste',
      :ch_ikscat                  => 'Abgabekategorie',
      :ch_ikscat_A                => 'Einmalige Abgabe auf ärztliche Verschreibung',
      :ch_ikscat_B                => 'Abgabe auf ärztliche Verschreibung',
      :ch_ikscat_C                => 'Abgabe nach Fachberatung durch Medizinalpersonen',
      :ch_ikscat_D                => 'Abgabe nach Fachberatung',
      :ch_ikscat_E                => 'Abgabe ohne Fachberatung',
      :city                       => 'Ort',
      :code_cid                   => 'Pharmazentralnummer',
      :code_festbetragsgruppe     => 'Festbetragsgruppe',
      :code_festbetragsstufe      => 'Festbetragsstufe',
      :code_prescription          => 'Rezeptpflichtig',
      :code_registration          => 'EU-Zulassungsnummer / AMD-Reg.-Nummer',
      :code_zuzahlungsbefreit     => 'Zuzahlungsbefreit',
      :comment                    => 'Anmerkung',
      :company                    => 'Zulassungsinhaber',
      :compare                    => 'Preisvergleich',
      :compare_remote             => 'Preisvergleich',
      :comparison_for0            => 'Preisvergleich für ',
      :comparison_for1            => '',
      :compositions               => 'Bestandteile',
      :compr_gz                   => 'GZ',
      :compr_zip                  => 'ZIP',
      :compression_label          => 'Gewünschte Komprimierung',
      :confirm_pass               => 'Bestätigung',
      :contact                    => 'Kontakt',
      :contact_url                => 'http://wiki.oddb.org/wiki.php/ODDB/Kontakt',
      :create_active_agent        => 'Wirkstoff hinzufügen',
      :create_composition         => 'Bestandteil hinzufügen',
      :download_description       => 'Datenbeschrieb',
      :download_example           => 'Beispiel-Download',
      :"download_howto_compendium_de.oddb.org.firefox.epub"     => 'Installation Firefox',
      :"download_howto_url_compendium_de.oddb.org.firefox.epub" => 'http://www.ywesee.com/pmwiki.php/Main/EPUB',
      :"download_howto_compendium_de.oddb.org.htc.prc"          => 'Installation HTC',
      :"download_howto_url_compendium_de.oddb.org.htc.prc"      => 'http://www.ywesee.com/pmwiki.php/Ywesee/HTC',
      :"download_howto_compendium_de.oddb.org.kindle.mobi"      => 'Installation Kindle',
      :"download_howto_url_compendium_de.oddb.org.kindle.mobi"  => 'http://www.ywesee.com/pmwiki.php/Ywesee/Kindle',
      :"download_howto_compendium_de.oddb.org.stanza.epub"      => 'Installation Stanza',
      :"download_howto_url_compendium_de.oddb.org.stanza.epub"  => 'http://www.ywesee.com/pmwiki.php/Ywesee/Stanza',
      :days                       => 'Tage', 
      :days0                      => '', 
      :days1                      => ' Tage', 
      :days_genitive0             => '', 
      :days_genitive1             => ' Tagen', 
      :days_one_genitive          => 'einem Tag',
      :ddd                        => 'Tagesdosis',
      :ddd_price_calculation      => 'Berechnung',
      :ddd_price_calculation0     => '( ',
      :ddd_price_calculation1     => ' / ',
      :ddd_price_calculation2     => ' ) x ( ',
      :ddd_price_calculation3     => ' / ',
      :ddd_price_calculation4     => ' ) = <b>EUR ',
      :ddd_price_calculation5     => ' / Tag </b>',
      :delete                     => 'Löschen',
      :delete_composition         => 'Bestandteil löschen',
      :delete_package_confirm     => 'Wollen Sie diese Packung wirklich löschen?',
      :delete_sequence_confirm    => 'Wollen Sie diese Sequenz wirklich löschen?',
      :display_grouped            => 'Zur ATC-Übersicht',
      :display_paged              => 'Alle Präparate anzeigen',
      :download                   => 'Download-Registrierung',
      :download_descr             => 'Der Download der Stammdaten ist kostenpflichtig. Bitte geben Sie Ihre Kontakt-Daten an und gehen Sie dann weiter zum Checkout.',
      :download_export_mail_body  => 'Die Bezahlung für Ihren CSV-Export konnte erfolgreich abgewickelt werden.',
      :download_export_mail_instr => 'Sie können die Daten mit dem folgenden Link abrufen:', 
      :download_mail_body         => 'Die Bezahlung für Ihren Download konnte erfolgreich abgewickelt werden.',
      :download_mail_instr        => 'Sie können die Daten mit den folgenden Links abrufen:',
      :download_info              => 'Mehr Infos zu den Stammdaten von de.ODDB.org',
      :downloads                  => 'Stammdaten Download',
      :dose                       => 'Stärke',
      :drugs                      => 'Medikamente',
      :drugs_atc_codes            => "ATC-Codes, DDD's:",
      :drugs_copay_free           => 'Zuzahlungsbefreite Arzneimittel:',
      :drugs_fixprices            => 'Arzneimittelfestbeträge:',
      :dstype                     => 'Art der Suche:',
      :ean0                       => 'EAN-13: ', 
      :ean1                       => '', 
      :e_duplicate_pzn0           => 'Die Pharmazentralnummer ',
      :e_duplicate_pzn1           => ' ist bereits vergeben.',
      :e_duplicate_registration0  => 'Die EU-Registrationsnummer ',
      :e_duplicate_registration1  => ' ist bereits vergeben.',
      :e_failed_turing_test       => 'Ihre Eingabe stimmt nicht mit dem Bild überein. Bitte versuchen Sie es noch einmal.',
      :e_missing_atc              => 'Bitte geben Sie einen gültigen ATC-Code an.',
      :e_unknown_atc0             => 'Der ATC-Code "',
      :e_unknown_atc1             => '" ist nicht bekannt.',
      :e_missing_downloads        => 'Bitte wählen Sie mindestens ein File zum Download aus.',
      :e_unknown_galenic_form0    => 'Die Galenische Form "',
      :e_unknown_galenic_form1    => '" ist nicht bekannt.',
      :e_unknown_substance0       => 'Die Substanz "',
      :e_unknown_substance1       => '" ist nicht bekannt.',
      :e_need_all_input           => 'Bitte füllen Sie alle Felder aus.',
      :e_query_short              => 'Ihr Such-Stichwort ergibt ein sehr grosses Resultat. Bitte verwenden Sie mindestens 3 Buchstaben.',
      :e_missing_days             => 'Bitte wählen Sie eine Zeitdauer.',
      :e_missing_code_cid         => 'Bitte geben Sie eine Pharmazentralnummer an.',
      :e_missing_company          => 'Bitte geben Sie einen Zulassungsinhaber an.',
      :e_missing_email            => 'Bitte geben Sie eine gültige E-Mail-Adresse an.',
      :e_missing_name             => 'Bitte geben Sie einen Namen an.',
      :e_state_expired            => 'Die Seite ist nicht mehr gültig.', 
      :e_unknown_company0         => 'Der Zulassungsinhaber "',
      :e_unknown_company1         => '" ist nicht bekannt.',
      :email                      => 'E-Mail',
      :email_not_public           => 'E-Mail wird nicht angezeigt.',
      :email_public               => 'E-Mail anzeigen',
      :email_public_false         => 'Ich will anonym bleiben.',
      :email_public_true          => 'Ich bin bereit, meine Erfahrungen mit diesem Medikament mit anderen Leuten auszutauschen. Meine Mail-Adresse muss nicht anonym bleiben.',
      :empty_comparison           => <<-EOS,
In unserer Datenbank wurden leider keine Produkte gefunden, 
die mit diesem Produkt verglichen werden können.
      EOS
      #
      :empty_packages             => <<-EOS,
Ihr Such-Stichwort hat zu keinem Suchergebnis geführt. Bitte
überprüfen Sie die Schreibweise und versuchen Sie es noch
einmal.
      EOS
      :equivalence_factor         => 'Wirkstärkenäquivalenzfaktor (waef)',
      :explain_compare            => 'Für einen Preisvergleich klicken Sie bitte auf den Medikamentennamen; zum Umsortieren auf den Tabellentitel.', 
      :explain_currency_convert   => 'Wechselkurs (1 EUR in CHF)',
      :explain_remote             => 'Rot = CH - Produkte', 
      :explain_zuzahlungsbefreit  => 'Gelb = Zuzahlungsbefreit', 
      :explain_search             => <<-EOS,
Vergleichen Sie einfach und schnell Medikamentenpreise.
Suchen Sie nach Medikamentname oder Wirkstoff.
      EOS
      :export                     => 'CSV-Export Datenerfassung',
      :export_csv                 => 'Resultat als CSV Exportieren',
      :export_descr               => 'Bitte geben Sie Ihre persönlichen Angaben ein und wählen Sie einen Benutzernamen und ein Passwort.',
      :fachinfo                   => 'Fachinformation',
      :feedback                   => 'Feedback',
      :feedback_alt0              => 'Feedback zu ',
      :feedback_alt1              => '',
      :feedback_changed           => 'Vielen Dank! Ihr Feedback wurde geändert. Sie können noch weitere Änderungen vornehmen.',
      :feedback_for0              => 'Feedback zu ',
      :feedback_for1              => ' in der Handelsform: ',
      :feedback_for2              => '',
      :feedback_for_sequence0     => 'Feedback zu ',
      :feedback_for_sequence1     => '',
      :feedback_by0               => 'Feedback von ', 
      :feedback_by1               => '<br/>erstellt am: ', 
      :feedback_by2               => '', 
      :feedback_feed_description  => 'Patienten- und Ärztefeedback zu Medikamenten im Schweizer Gesundheitsmarkt',
      :feedback_feed_title        => 'Patienten- und Ärztefeedback zu Medikamenten',
      :feedback_message           => 'Meine Erfahrung / Meine persönliche Meinung zu diesem Medikament ist: (max. 400 Zeichen)',
      :feedback_preview0          => '',
      :feedback_preview1          => ' in der Handelsform: ',
      :feedback_preview2          => '',
      :feedback_saved             =>  'Vielen Dank! Ihr Feedback wurde gespeichert. Sie können jetzt noch Änderungen vornehmen.',
      :feedback_short             => 'FB',
      :festbetragsstufe           => ' (Gesetzestext)',
      :festbetragsstufe_url       => 'http://www.sozialgesetzbuch-bundessozialhilfegesetz.de/buch/sgbv/35.html',
      :festbetragsstufe_1         => 'Arzneimittel mit denselben Wirkstoffen',
      :festbetragsstufe_2         => 'Arzneimittel mit pharmakologisch-therapeutisch vergleichbaren Wirkstoffen, insbesondere mit chemisch verwandten Stoffen',
      :festbetragsstufe_3         => 'Arzneimittel mit therapeutisch vergleichbarer Wirkung, insbesondere Arzneimittelkombinationen',
      :fachinfo_url               => 'URL zur Fachinformation',
      :galenic_form               => 'Galenische Form',
      :google                     => 'G',
      :google0                    => 'Google-Suche nach ',
      :google1                    => '',
      :home                       => 'Home',
      :html_title                 => 'DE - ODDB.org',
      :html_owner                 => 'Open Drug Database',
      :indication                 => 'Indikation',
      :item_good_experience       => 'Persönliche Erfahrung',
      :item_good_experience_true  => 'Ich habe mit diesem Medikament positive Erfahrungen gemacht.',
      :item_good_experience_false => 'Ich habe mit diesem Medikament negative Erfahrungen gemacht.',
      :item_good_impression       => 'Persönlicher Eindruck',
      :item_good_impression_true  => 'Dieses Medikament hat einen guten Eindruck auf mich gemacht.',
      :item_good_impression_false => 'Dieses Medikament hat keinen guten Eindruck auf mich gemacht.',
      :item_helps                 => 'Wirkung',
      :item_helps_true            => 'Dieses Medikament hat mir geholfen.',
      :item_helps_false           => 'Dieses Medikament hat mir nicht geholfen.',
      :item_recommended           => 'Empfehlung',
      :item_recommended_true      => 'Ich werde dieses Medikament weiterempfehlen.',
      :item_recommended_false     => 'Ich werde dieses Medikament nicht weiterempfehlen.',
      :lgpl_license               => 'LGPL',
      :login                      => 'Anmelden',
      :login_                     => 'Anmelden',
      :logout                     => 'Abmelden',
      :logo                       => 'de.oddb.org - peer reviewed open drug database',
      :minus                      => '-',
      :more                       => '+',
      :name                       => 'Name',
      :name_first                 => 'Vorname',
      :name_last                  => 'Nachname',
      :new_package                => 'Neue Packung',
      :new_sequence               => 'Neue Sequenz',
      :no                         => 'Nein',
      :no_active_agents           => 'Wirkstoffe unbekannt',
      :oddb_ch                    => 'Schweiz',
      :oddb_chde                  => 'Deutschland - Schweiz',
      :oddb_de                    => 'Deutschland',
      :oddb_version               => 'Commit-ID',
      :package                    => 'Details',
      :packages                   => 'Präparate',
      :packages_admin             => 'Packungen',
      :package_and_substances     => 'Packungsgrösse und Wirkstoffe',
      :package_details_for0       => 'Packungsdetails für "',
      :package_details_for1       => '"',
      :pager0                     => 'Seite ',
      :pager1                     => ' von ',
      :pager2                     => ':',
      :parts                      => 'Teilpackungen',
      :pass                       => 'Passwort',
      :patinfo                    => 'Gebrauchsinformation',
      :paypal_completed           => 'Bezahlung erfolgreich übermittelt',
      :paypal_e_expired0          => '',
      :paypal_e_expired1          => ': die Gültigkeitsdauer ist abgelaufen (',
      :paypal_e_expired2          => ')',
      :paypal_e_invalid_time      => 'Ungültige Zeitangabe',
      :paypal_e_missing_invoice   => 'Ihre Transaktion ist bei uns nicht registriert. Setzen Sie sich bitte per <a href="mailto:zdavatz@ywesee.com">E-Mail</a> mit uns in Verbindung.',
      :paypal_explain_login0      => 'Ihr PowerUser-Account ist bereit. Bitte melden Sie sich',
      :paypal_explain_login1      => ' hier ',
      :paypal_explain_login2      => 'erneut mit E-Mail und Passwort an.',
      :paypal_explain_poweruser   => 'Sie sind bereits angemeldet und können sofort weitersuchen.',
      :paypal_msg_succ_p          => 'Vielen Dank! Sie können jetzt mit den untigen Links die Daten downloaden. Diese Links wurden Ihnen auch in einem E-Mail zugestellt.',
      :paypal_msg_succ_download   => 'Vielen Dank! Sie können jetzt mit dem untigen Link die Daten downloaden. Dieser Link wurden Ihnen auch in einem E-Mail zugestellt.',
      :paypal_msg_succ_poweruser  => 'Vielen Dank! Als angemeldeter Benutzer können Sie jetzt ohne Beschränkung Abfragen vornehmen.',
      :paypal_msg_unconfirmed     => 'Ihre Bezahlung ist von PayPal noch nicht bestätigt worden. Sobald dies geschieht werden wir Sie per E-Mail benachrichtigen.',
      :paypal_failed              => 'Fehler',
      :patinfo_url                => 'URL zur Gebrauchsinformation',
      :phone                      => 'Telefon',
      :plus                       => '+',
      :postal_code                => 'PLZ',
      :poweruser                  => 'Power-User Datenerfassung',
      :poweruser_descr            => 'Bitte geben Sie Ihre persönlichen Angaben ein und wählen Sie einen Benutzernamen und ein Passwort.',


      :poweruser_mail_body        => 'Die Bezahlung für Ihren Power-User-Account konnte erfolgreich abgewickelt werden.', 
      :poweruser_mail_instr0      => 'Um während ', 
      :poweruser_mail_instr1      => ' uneingeschränkt Abfragen tätigen zu können, melden sie sich bitte unter ',
      :poweruser_mail_instr2      => ' an.',
      :poweruser_mail_salut0      => 'Guten Tag ',
      :poweruser_mail_salut1      => ' ',
      :poweruser_mail_salut2      => '',



      :poweruser_mail_subject     => 'Power-User bei ODDB.org',
      :prescription_free          => 'O',
      :prescription_needed        => 'R',
      :price_difference           => 'Abweichung vom Festbetrag',
      :price_exfactory            => 'Fabrikabgabepreis',
      :price_festbetrag           => 'Festbetrag',
      :price_public               => 'Apothekenverkaufspreis',
      :price_zuzahlung            => 'Zuzahlung/Selbstbeteiligung',
      :proceed_download           => 'Weiter zur Adresseingabe',
      :proceed_export             => 'CSV-Export',
      :proceed_poweruser          => 'Weiter',
      :product                    => 'Produkt',
      :product_details_for0       => 'Produktdetails für "',
      :product_details_for1       => '"',
      :products                   => 'Arzneimittel A-Z',
      :pzn0                       => 'Pharmazentralnummer: ',
      :pzn1                       => '',
      :query_info                 => 'Bitte HIER Such-Stichwort eingeben',
      :query_limit0               => 'Abfragebeschränkung auf ',
      :query_limit1               => ' Abfragen pro Tag.',
      :query_limit_login          => 'B) Falls Sie bereits als Benutzer registriert sind, geben Sie Ihr E-Mail und Passwort an um zur gewünschten Ansicht zu gelangen:',
      :query_limit_more_info      => 'Mehr Informationen',
      :query_limit_new_user       => 'A) Falls Sie noch nicht als Benutzer registriert sind, lesen Sie bitte folgendes: ',
      :query_limit_explain0       => 'de.ODDB.org misst die Anzahl Abfragen von einer IP-Adresse. Bei Ihrer IP-Adresse &lt;',
      :query_limit_explain1       => '&gt; haben wir innerhalb eines Tages mehr als ',
      :query_limit_explain2       => ' Abfragen gemessen.<br/>Gerne möchten wir Ihnen folgende Möglichkeiten anbieten, direkter und schneller zu Ihrer gewünschten Dienstleistung zu gelangen.',
      :query_limit_poweruser_1    => 'Tages-User', 
      :query_limit_poweruser_30   => 'Durchschnitts-User', 
      :query_limit_poweruser_365  => 'Power-User', 
      :query_limit_poweruser_a0   => ' Lösen Sie ein <b>jährliches Abo</b> für <b>EUR ',
      :query_limit_poweruser_a1   => '</b>. Mit diesem Abo können Sie de.ODDB.org für ein Jahr uneingeschränkt verwenden. Die Gebühr gilt pro Benutzer.', 
      :query_limit_poweruser_b0   => ' Sie machen mehr als ',
      :query_limit_poweruser_b1   => ' Abfragen pro Tag, möchten de.ODDB.org aber nur mal für <b>einen Monat</b> testen? Dies kostet Sie <b>EUR ',
      :query_limit_poweruser_b2   => '</b> pro Monat. Die Gebühr gilt pro Benutzer.', 
      :query_limit_poweruser_c0   => ' Sie möchten de.ODDB.org nur für einen Tag uneingeschränkt testen? Dies kostet Sie <b>EUR ',
      :query_limit_poweruser_c1   => '</b> pro <b>24h</b>. Die Gebühr gilt pro Benutzer.', 
      :query_limit_poweruser      => 'Sind Sie von de.ODDB.org überzeugt und benutzen Sie de.ODDB.org regelmässig? Wir haben für Sie folgende 3 Optionen:',
      :query_limit_poweruser_     => 'Unbekannter User', 
      :query_limit_thanks         => 'C) Vielen Dank!',
      :query_limit_thanks0        => 'Falls Sie Fragen, Bemerkungen oder Verbesserungsvorschläge haben senden Sie ein E-Mail an ',
      :query_limit_thanks1        => ' oder rufen Sie +41 43 540 05 50 an.',
      :query_limit_welcome        => 'Geschätzer Kunde, willkommen auf de.ODDB.org',
      :registration               => 'Registration',
      :reset                      => 'Zurücksetzen',
      :result                     => 'Suchresultat',
      :salutation                 => 'Anrede',
      :salutation_f               => 'Frau',
      :salutation_m               => 'Herr',
      :sb_digg                    => 'Digg',
      :sb_delicious               => 'Bookmark',
      :sb_simpy                   => 'Simpy',
      :sb_stumble                 => 'Stumble',
      :screencast                 => 'Video-Anleitung (Screencast)',
      :screencast_url             => 'http://www.youtube.com/watch?v=TFqW4hmLzn8',
      :search                     => 'Suchen',
      :sequence                   => 'Sequenz',
      :sequence_details_for0      => 'Sequenzdetails für "',
      :sequence_details_for1      => '"',
      :sequences                  => 'Sequenzen',
      :square_fachinfo            => 'FI',
      :square_patinfo             => 'GI',
      :size                       => 'Packungsgrösse',
      :substance                  => 'Inhaltsstoff',
      :th_active_agents           => 'Wirkstoff',
      :th_administration          => 'Verabreichung',
      :th_atc                     => 'ATC-Code',
      :th_code_festbetragsstufe   => 'FB-Stufe',
      :th_code_zuzahlungsbefreit  => 'Zuzahlungsbefreit',
      :th_comment                 => 'Kommentar',
      :th_company                 => 'Hersteller',
      :th_ddd_prices              => 'TK',
      :th_difference              => '%',
      :th_dose                    => 'Tagesdosis',
      :th_doses                   => 'Stärke',
      :th_download_howto          => 'Anleitung',
      :th_package_infos           => 'Zuzahl. / Rezept',
      :th_price_1                 => 'Einmalig',
      :th_price_12                => '1 Jahr 12 Updates',
      :th_price_difference        => 'ABS-Differenz',
      :th_price_exfactory         => 'FAP',
      :th_price_festbetrag        => 'FB',
      :th_price_public            => 'AVP',
      :th_price_zuzahlung         => 'ZZ',
      :th_product                 => 'Präparat',
      :th_size                    => 'Packungsgrösse',
      :time_format_long           => '%A, %d. %B %Y, %H:%M:%S',
      :title_found0               => 'Suchergebnis für "',
      :title_found1               => '", Total ',
      :title_found2               => ' Präparate',
      :total_brutto               => 'Total inkl. MwSt.:',
      :total_netto                => 'Total:',
      :tradename                  => 'Markenname',
      :tt_active_agents           => 'Die Stärke bezieht sich auf Darreichungsform-Einheit (Tablette, Zäpfchen, Sirup, etc). Siehe auch: ',
      :tt_active_agents_link      => 'Darreichungsformen',
      :tt_atc                     => <<-EOS,
The field of drug utilization research has attracted increasing
interest since its infancy in the 1960s. At a symposium in Oslo 
in 1969 entitled The Consumption of Drugs, it was agreed that an
internationally accepted classification system for drug consumption
studies was needed. At the same symposium the Drug Utilization Research
Group (DURG) was established and tasked with the development of
internationally applicable methods for drug utilization research...
      EOS
      # rcov needs a comment between two here-documents
      :tt_code_festbetragsstufe   => <<-EOS,
Gruppen "vergleichbarer" Arzneimittel können nach unterschiedlichen Kriterien gebildet werden, deshalb werden drei Stufen der Vergleichbarkeit unterschieden: Festbetragsgruppen der Stufe 1 werden aus Arzneimitteln mit denselben Wirkstoffen gebildet. Festbetragsgruppen der Stufe 2 werden aus Arzneimitteln gebildet, deren Wirkstoffe pharmakologisch, insbesondere chemisch, und dabei gleichzeitig auch hinsichtlich ihrer therapeutischen Wirkung vergleichbar sind. Festbetragsgruppen der Stufe 3 werden aus Arzneimitteln gebildet, die nicht hinsichtlich ihrer Wirkstoffe, aber hinsichtlich ihrer therapeutischen Wirkung vergleichbar sind...

Quelle: 
      EOS
      # rcov needs a comment between two here-documents
      :tt_code_zuzahlungsbefreit       => <<-EOS,
Zuzahlungsbefreite Arzneimittel:

Die Spitzenverbände der Krankenkassen haben am 11.05.2006 gemeinsam und einheitlich für bestimmte zu Lasten ihrer Krankenkassen abgegebene Arzneimittel Zuzahlungsbefreiungsgrenzen festgelegt.

Bei der Verordnung von Arzneimitteln, deren Apothekenverkaufspreise inkl. MwSt. den Wert der jeweiligen Zuzahlungsbefreiungrenze nicht überschreiten, sind Versicherte ab dem 1. Juli 2006 von der gesetzlichen Zuzahlung nach § 31 Abs. 3 Satz 1 SGB V befreit.

Quelle: 
      EOS
      :tt_company                 => 'Der Hersteller oder Zulassungsinhaber des Produkts',
      :tt_ddd_prices              => 'Tageskosten',
      :tt_price_festbetrag        => <<-EOS,
Festbetrag: DIMDI hat die Aufgabe, die von den Spitzenverbänden der
Krankenkassen erstellten und veröffentlichten Übersichten über
sämtliche Festbeträge und die betroffenen Arzneimittel im Internet
abruffähig zu veröffentlichen...
      EOS
      :tt_price_difference        => 'Absolute Differenz zwischen Preis und Festbetrag',
      :tt_price_exfactory         => 'Preis: Fabrikabgabepreis exkl. MwSt. in Euro',
      :tt_price_public            => 'Preis: Apothekenverkaufspreis inkl. MwSt. in Euro',
      :tt_price_zuzahlung         => 'Preis: Zuzahlung/Selbstbeteiligung in Euro',
      :tt_product                 => 'Präparat ist der Handelsname des Medikaments',
      :unsaved                    => '(unsaved)',
      :update                     => 'Speichern',
      :vat                        => 'MwSt.',
      :welcome_user0              => 'Willkommen bei de.oddb.org! Sie sind angemeldet als ',
      :welcome_user1              => '',
      :welcome_data_declaration   => '** Herkunftsdeklaration der Daten **',
      :welcome_drugs              => <<-EOS,
Willkommen bei de.oddb.org, dem aktuellsten 
Medikamenten-Preisvergleichs-Portal Deutschlands.
      EOS
      :who_ddd                    => 'WHO-DDD',
      :yes                        => 'Ja',
      :ywesee                     => 'ywesee.com',
      :ywesee_contact_email       => 'zdavatz@ywesee.com',
      :ywesee_contact_href        => 'mailto:zdavatz@ywesee.com',
    }
  }
  RESOURCES = {
    :logo       => 'logo.png', 
    :css        => 'oddb.css',
    :downloads  =>  'downloads',
    :javascript => 'javascript',
    :rss        => 'rss',
    :rss_img    => 'livemarks16.png',
  }
  def base_url
    [@session.http_protocol + ':/', @session.server_name,
      @language, @session.zone].compact.join("/")
  end
  def captcha
    outdir = File.join(ODDB.config.var, 'captcha')
    dict = File.join(ODDB.config.data_dir, 'captcha', language)
    FileUtils.mkdir_p outdir
    @turing ||= Turing::Challenge.new(:outdir => outdir, :dictionary => dict)
  end
  def csv_components
    [ :pzn, :product, :active_agents, :size, :price_exfactory, :price_public,
      :price_festbetrag, :ddd_prices, :company, ]
  end
  def currency_factor
    1.0
  end
  def generate_challenge
    challenge = nil
    Thread.exclusive {
      kcode = $KCODE
      $KCODE = 'NONE'
      challenge = captcha.generate_challenge
      @@turing_files.store challenge.object_id, challenge.file
      $KCODE = kcode
    }
    ObjectSpace.define_finalizer challenge, @@turing_finalizer
    challenge
  end
  def legend_components
    { [0,0] => 'explain_zuzahlungsbefreit' }
  end
  def price_factor
    tax_factor * currency_factor
  end
  def products_components
    {
      [0,0] => :fachinfo_link,
      [1,0] => :patinfo_link,
      [2,0] => :product,
      [3,0] => :atc,
      [4,0] => :company,
      [5,0] => :google,
    }
  end
  def result_components
    {
      [0,0] => :fachinfo_link,
      [1,0] => :patinfo_link,
      [2,0] => :product,
      [3,0] => :active_agents,
      [4,0] => :size, 
      [5,0] => :price_exfactory,
      [6,0] => :price_public,
      [7,0] => :price_festbetrag,
      [8,0] => :ddd_prices,
      [9,0] => :price_zuzahlung,
      [10,0] => :company,
      [11,0] => :package_infos,
      [12,0] => :feedback,
      [13,0] => :google,
    }
  end
  def tax_factor
    (1 + tax_factor_add) / (1 + tax_factor_sub)
  end
  def tax_factor_add
    0
  end
  def tax_factor_sub
    0
  end
end
class LookandfeelWrapper < SBSM::LookandfeelWrapper
  def base_url
    [@session.http_protocol + ':/', @session.server_name,
      @language, @session.zone].compact.join("/")
  end
  def price_factor
    tax_factor * currency_factor
  end
  def tax_factor
    (1 + tax_factor_add) / (1 + tax_factor_sub)
  end
end
class LookandfeelJustMedical < LookandfeelWrapper
  DICTIONARIES = {
    "de" =>  {
      :contact_url => 'http://www.just-medical.de/imprint.cfm',
    }
  }
  DISABLED = [ :country_links, :logo ]
  ENABLED = [
    # Features:
    :external_css, :explain_price, 
    # Navigation-Links:
    :home, :products, :atc_browser,
  ]
  RESOURCES = {
    :external_css  =>  'http://www.just-medical.com/css/de.oddb.css',
  }
  def result_components
    {
      [0,0] => :fachinfo_link,
      [1,0] => :patinfo_link,
      [2,0] => :product,
      [3,0] => :active_agents,
      [4,0] => :size,
      [5,0] => :price_exfactory,
      [6,0] => :price_public,
      [7,0] => :price_festbetrag,
      [8,0] => :ddd_prices,
      [9,0] => :company,
      [10,0] => :package_infos,
      [11,0] => :feedback,
      [12,0] => :google,
    }
  end
end
class LookandfeelMeineMedikamente < LookandfeelWrapper
  DICTIONARIES = {
    'de' => { 
      :ddd_price_calculation4 => ' ) = <b>CHF ',
      :html_title             => 'CH | DE - ODDB.org',
      :html_owner             => 'Open Drug Database',
      :price_local            => 'Preis Schweiz (CHF)',
      :price_db               => 'Preis Deutschland (CHF)',
      :screencast_url         => 'http://www.youtube.com/watch?v=8lWYIzjlOe0',
      :tax_add                => 'MwSt. Schweiz (7.6%)',
      :tax_sub                => 'MwSt. Deutschland (19%)',
      :tt_price_public        => 'Preis: Apothekenverkaufspreis inkl. MwSt. in CHF',
      :welcome_drugs            => <<-EOS,
Willkommen bei chde.oddb.org, dem aktuellsten
Medikamenten-Portal für den Preisvergleich zwischen
der Schweiz und Deutschland. Alle Preise sind in CHF.
      EOS
    },
  }
  ENABLED = [
    # Features:
    :explain_price, :google_ads, :remote_databases, :query_limit, :welcome,
    :screencast, :social_bookmarks,
    # Navigation-Links:
    :atc_browser, :contact, :home, :products, 
  ]
  RESOURCES = {
    :logo => 'logo.png', 
  }
  def currency_factor
    @factor ||= Currency.rate('EUR', 'CHF')
  end
  def legend_components
    { 
      [0,0] => 'explain_remote',
      [0,1] => 'explain_zuzahlungsbefreit', 
    }
  end
  def products_components
    {
      [0,0] => :product,
      [1,0] => :atc,
      [2,0] => :company,
      [3,0] => :google,
    }
  end
  def result_components
    {
      [0,0] => :product,
      [1,0] => :active_agents,
      [2,0] => :size, 
      [3,0] => :price_exfactory,
      [4,0] => :price_public,
      [5,0] => :ddd_prices,
      [6,0] => :company,
      [7,0] => :package_infos,
      [8,0] => :google,
    }
  end
  def tax_factor_add
    7.6 / 100.0
  end
  def tax_factor_sub
    19.0 / 100.0
  end
end
class LookandfeelFactory < SBSM::LookandfeelFactory
  BASE = Lookandfeel
  WRAPPERS = {
    'mm'           => [ LookandfeelMeineMedikamente ],
    'just-medical' => [ LookandfeelJustMedical ],
  }
end
class LookandfeelStub < Lookandfeel
  def initialize(language, zone='drugs')
    @language = language
    @zone = zone
    set_dictionary(@language)
  end
  def base_url
    sprintf "http://%s/%s/%s", ODDB.config.server_name, @language, @zone
  end
end
    end
  end
end
