
*CREAZIONE E MODIFICA DATASET

cd "C:\Users\paren\Desktop\_MAGISTRALE\ValutazioneSistemiSanitari\Stata\presentazione"
import excel "C:\Users\paren\Desktop\_MAGISTRALE\ValutazioneSistemiSanitari\Stata\presentazione\C_17_dataset_18_0_upFile.xlsx", sheet("C_17_dataset_18_0_upFile") firstrow clear
rename DescrizioneRegione regione
*unisco le due due prov in un unica regione
replace regione="TRENTINO ALTO ADIGE" if regione =="PROV. AUTON. BOLZANO"
replace regione="TRENTINO ALTO ADIGE" if regione =="PROV. AUTON. TRENTO"

*TRASFORMO LE VAERIABILI NUMERICHE DA STRINGHE A NUMERO
*sopratutto le variabili finali (quelle che descrivono il numro di posti letto) è fondamentale che siano varibili numeriche e non stringhe, altrimenti non siamo in grado di fare analisi numeriche (es media)
*metodo per creare una variabile dicotomica che evidenzia le osservazioni non numeriche
gen var_non_numerica = . 
replace var_non_numerica = 0 if regexm(Totalepostiletto, "^[0-9]+(\\.[0-9]+)?$") 
replace var_non_numerica = 1 if var_non_numerica != 0
*individuo le osservazioni non numuriche
list Totalepostiletto if var_non_numerica == 1
*ci sono tre variabili con nd nel numero dei posti letto. le elimino
drop if var_non_numerica==1
*trasformo le variabili numeriche da stringhe a numero
destring Totalepostiletto , replace
destring PostilettoDaySurgery , replace
destring PostilettoDayHospital , replace
destring Postilettodegenzaapagamento , replace
destring Postilettodegenzaordinaria, replace
*elimino la variabile che avevo creato prima per trovare le stringhe tra i numeri
drop var_non_numerica

*UNISCO VALORI DI POPOLAZIONE REGIONE PER REGIONE 
*perche questo ci serve per calcolare il numero di posti letto ogni 1000 abitanti
*il file con i valori di popolazione per ogni regione dal 2010 al 2019 è stato scaricato dal sito ufficiale dell'ISTAT
*usiamo il comando merge
rename Anno anno
save "C:\Users\paren\Desktop\_MAGISTRALE\ValutazioneSistemiSanitari\Stata\presentazione\ospedali.dta", replace
*uso un merge many to many (m:m) perche su entrambe le variabili da unire ho più osservazioni
merge m:m anno regione using "C:\Users\paren\Desktop\_MAGISTRALE\ValutazioneSistemiSanitari\Stata\presentazione\regioni.dta"
*elimino 10 osservazioni che sono completamente prive di dati
drop if popolazione ==.
*elimino la variabile _merge perche non serve piu
drop _merge

*CALCOLO IL NUMERO DI POSTI LETTO OGNI 1000 ABITANTI
gen Postilettodegenzaordinaria1k = Postilettodegenzaordinaria / popolazione * 1000
gen Postilettodegenzaapagamento1k = Postilettodegenzaapagamento / popolazione * 1000
gen PostilettoDayHospital1k = PostilettoDayHospital / popolazione * 1000
gen PostilettoDaySurgery1k = PostilettoDaySurgery / popolazione * 1000
gen Totalepostiletto1k = Totalepostiletto / popolazione * 1000

*rinomino le variabili troppo lunghe per facilitarne l'uso
rename CodiceRegione cod_regione
rename CodiceAzienda cod_azienda
rename TipoAzienda tipo_azienda
rename Codicestruttura cod_struttura
rename Denominazionestruttura nome_struttura
rename Indirizzo indirizzo
rename CodiceComune cod_comune
rename Comune comune
rename Siglaprovincia provincia
rename Codicetipostruttura cod_tipo_struttura
rename Descrizionetipostruttura tipo_struttura
rename  TipodiDisciplina disciplina
rename  Postilettodegenzaordinaria pl_deg_ord
rename  Postilettodegenzaapagamento pl_deg_pag
rename  PostilettoDayHospital pl_day_hosp
rename  PostilettoDaySurgery pl_day_surg
rename  Totalepostiletto totale_pl
rename  Postilettodegenzaordinaria1k pl_deg_ord1k
rename  Postilettodegenzaapagamento1k pl_deg_pag1k
rename  PostilettoDayHospital1k pl_day_hosp1k
rename  PostilettoDaySurgery1k pl_day_surg1k
rename  Totalepostiletto1k totale_pl1k

*CREO UNA VARIABILE CHE ESPRIMA IL NUMERO DI POSTI LETTO /1000 ABITANTI REGIONE PER REGIONE E ANNO PER ANNO
*creo una nuova variabilie regione anno in cui unisco le due variabili
*anno non è una stringa, quindi aggiungo prima il comando string, che dice a stata di utilizzare una variabile numerica sotto forma di stringa
gen regione_anno = regione + string(anno)
*questa operazione è stata fatta per calcolare i valori regione per regione e anno per anno, poiche la funzione egen non supportava due by()
*calcolo la nuova variabile che ci dice quanti posti letto ci sono regione per regione e anno per anno
egen totale_pl1k_reg = total( totale_pl1k ), by(regione_anno)
egen pl_day_hosp1k_reg = total( pl_day_hosp1k ), by(regione_anno)
egen pl_day_surg1k_reg = total( pl_day_surg1k ), by(regione_anno)
egen pl_deg_ord1k_reg = total( pl_deg_ord1k ), by(regione_anno)
egen pl_deg_pag1k_reg = total( pl_deg_pag1k ), by(regione_anno)

*elimino le variabili che non mi servono
drop cod_regione cod_struttura nome_struttura indirizzo comune cod_comune

*CREO UNA VARIABILE CHE ESPRIMA IL NUMERO DI POSTI LETTO (RIAB/LUNGODEG) /1000 ABITANTI REGIONE PER REGIONE E ANNO PER ANNO
*creo variabile che esprima se i posti letto siano lungodegenza/riabilitazione o meno
gen riab_lungodeg =1
replace riab_lungodeg=0 if disciplina=="ACUTI"
*creo variabile che calcoli ospedale per ospedale il numero di posti letto riab/lungodeg
gen totale_pl_riab = totale_pl * riab_lungodeg
*calcolo i posti letto riab ogni 1000 abitanti
gen totale_pl_riab1k = totale_pl_riab / popolazione * 1000
*calcolo la nuova variabile che ci dice quanti posti letto riab ci sono regione per regione e anno per anno
egen totale_pl_riab1k_reg = total( totale_pl_riab1k ), by(regione_anno)

*CREO VARIABILE TOTALE POSTI LETTO REGIONE >3,7 (LIMITE LEGISLATIVO A PARTIRE DAL 2015)
gen totale_pl1k_in_eccesso = 0
replace totale_pl1k_in_eccesso = 1 if totale_pl1k_reg>3.7
*CREO VARIABILE POSTI LETTO RIAB/LUNGODEG REGIONE >0,7 (LIMITE LEGISLATIVO A PARTIRE DAL 2015)
gen totale_pl_riab1k_in_eccesso = 0
replace totale_pl_riab1k_in_eccesso = 1 if totale_pl_riab1k_reg>.7

*RIMUOVO LE INFORMAZIONI NON PIU NECESSARIE
*uso il comando collapse
*l'obiettivo è avere un dataset con 210 osservazioni (21 regioni per 10 anni) conservando le variabili di interesse di studio
collapse totale_pl1k_reg totale_pl1k_in_eccesso totale_pl_riab1k_reg totale_pl_riab1k_in_eccesso , by( anno regione )


*ANALISI

*DESCRITTIVE
*calcolo la media di posti letto ogni mille abitanti 
*PROBLEMA: queste medie sovrapesano le regioni piccole a scapito di quelle grandi perche ciascuna regione ha peso uno
*potremmo aggiungere la popolazione come dato da aggiungere nel collapse, pero poi non saprei bene come calcolare la media pesata
summarize totale_pl1k_reg if anno <= 2015
summarize totale_pl1k_reg if anno > 2015
summarize totale_pl_riab1k_reg if anno <= 2015
summarize totale_pl_riab1k_reg if anno > 2015
*calcolo il numero di regioni 

*QUA VANNO CONTINUATE LE DESCRITTIVE E POI VA FATTO IL LAVORO SULLA DIFFERENZA TRA DIFFERENZE












*MAPPE
save "C:\Users\paren\Desktop\_MAGISTRALE\ValutazioneSistemiSanitari\Stata\presentazione\dati.dta" ,replace

*MAPPA TOTALE POSTI LETTO OGNI MILLE ABITANTI 2013
*salvo perche modifico il dataset originale. In questo modo posso sempre tornare ad avere il dataset di partenza
use "C:\Users\paren\Desktop\_MAGISTRALE\ValutazioneSistemiSanitari\Stata\presentazione\dati.dta", clear
* voglio avere il dataset con tutte le regioni, ma con solo un anno e una sola variabile
*tolgo le altre variabili
drop totale_pl_riab1k_in_eccesso totale_pl_riab1k_reg totale_pl1k_in_eccesso
*tengo solo un anno
keep if anno == 2013
drop anno
*installo pacchetti, se non vanno le mappe togli il commento ai comandi che installano i pacchetti
*ssc install palettes, replace
*ssc install colrspace
*ssc install spmap, replace
*rinomino le regioni
replace regione="Piemonte" if regione=="PIEMONTE"
replace regione="Valle d'Aosta" if regione=="VALLE D`AOSTA"
replace regione="Lombardia" if regione=="LOMBARDIA"
replace regione="Veneto" if regione=="VENETO"
replace regione="Trentino-Alto Adige" if regione=="TRENTINO ALTO ADIGE"
replace regione="Liguria" if regione=="LIGURIA"
replace regione="Friuli Venezia Giulia" if regione=="FRIULI VENEZIA GIULIA"
replace regione="Emilia-Romagna" if regione=="EMILIA ROMAGNA"
replace regione="Toscana" if regione=="TOSCANA"
replace regione="Umbria" if regione=="UMBRIA"
replace regione="Marche" if regione=="MARCHE"
replace regione="Abruzzo" if regione=="ABRUZZO"
replace regione="Molise" if regione=="MOLISE"
replace regione="Lazio" if regione=="LAZIO"
replace regione="Puglia" if regione=="PUGLIA"
replace regione="Campania" if regione=="CAMPANIA"
replace regione="Calabria" if regione=="CALABRIA"
replace regione="Sicilia" if regione=="SICILIA"
replace regione="Sardegna" if regione=="SARDEGNA"
replace regione="Basilicata" if regione=="BASILICATA"
rename regione DEN_REG
*faccio il merge col file per le mappe
*il merge deve dare match 20su20
merge 1:1 DEN_REG using reg-attr
*penso che questo comando serva a ridurre i decimali
format totale_pl1k_reg %8.2f
*qua possiamo modificare i colori
colorpalette Reds, nograph n(10)
*mappa
spmap totale_pl1k_reg using reg-coord, id(stid)   fcolor(`r(p)')  title("TOTALE POSTI LETTO OGNI MILLE ABITANTI 2013") 



*MAPPA POSTI LETTO RIABILITAZIONE/LUNGODEGENZA OGNI MILLE ABITANTI 2013
use "C:\Users\paren\Desktop\_MAGISTRALE\ValutazioneSistemiSanitari\Stata\presentazione\dati.dta", clear
* voglio avere il dataset con tutte le regioni, ma con solo un anno e una sola variabile
*tolgo le altre variabili
drop totale_pl1k_reg totale_pl_riab1k_in_eccesso  totale_pl1k_in_eccesso
*tengo solo un anno
keep if anno == 2013
drop anno
*installo pacchetti, se non vanno le mappe togli il commento ai comandi che installano i pacchetti
*ssc install palettes, replace
*ssc install colrspace
*ssc install spmap, replace
*rinomino le regioni
replace regione="Piemonte" if regione=="PIEMONTE"
replace regione="Valle d'Aosta" if regione=="VALLE D`AOSTA"
replace regione="Lombardia" if regione=="LOMBARDIA"
replace regione="Veneto" if regione=="VENETO"
replace regione="Trentino-Alto Adige" if regione=="TRENTINO ALTO ADIGE"
replace regione="Liguria" if regione=="LIGURIA"
replace regione="Friuli Venezia Giulia" if regione=="FRIULI VENEZIA GIULIA"
replace regione="Emilia-Romagna" if regione=="EMILIA ROMAGNA"
replace regione="Toscana" if regione=="TOSCANA"
replace regione="Umbria" if regione=="UMBRIA"
replace regione="Marche" if regione=="MARCHE"
replace regione="Abruzzo" if regione=="ABRUZZO"
replace regione="Molise" if regione=="MOLISE"
replace regione="Lazio" if regione=="LAZIO"
replace regione="Puglia" if regione=="PUGLIA"
replace regione="Campania" if regione=="CAMPANIA"
replace regione="Calabria" if regione=="CALABRIA"
replace regione="Sicilia" if regione=="SICILIA"
replace regione="Sardegna" if regione=="SARDEGNA"
replace regione="Basilicata" if regione=="BASILICATA"
rename regione DEN_REG
*faccio il merge col file per le mappe
*il merge deve dare match 20su20
merge 1:1 DEN_REG using reg-attr
*riduco a due decimali dopo la virgola
format totale_pl_riab1k_reg %8.2f
*qua possiamo modificare i colori
colorpalette Reds, nograph n(10)
*mappa
spmap totale_pl_riab1k_reg using reg-coord, id(stid)   fcolor(`r(p)')  title("TOTALE POSTI LETTO RIABILITAZIONE/LUNGODEGENZA OGNI MILLE ABITANTI 2013") 






*Differences-in-Differences
use "C:\Users\paren\Desktop\_MAGISTRALE\ValutazioneSistemiSanitari\Stata\presentazione\dati.dta", clear
* Generiamo come prima cosa la variabile post , in base all'anno di uscita del decreto ministeriale
gen post=(anno>=2015)
*il treatment è totale_pl1k_in_eccesso
*creo una variabile che identifichi trattati e non trattati
*per noi quelli trattati erano quelli con posti letto in eccesso ovvero sopra 3.7
gen treated = 0
replace treated=1 if regione=="EMILIA ROMAGNA" 
replace treated=1 if regione=="FRIULI VENEZIA GIULIA" 
replace treated=1 if regione=="LIGURIA"
replace treated=1 if regione=="LOMBARDIA"
replace treated=1 if regione=="MARCHE"
replace treated=1 if regione=="MOLISE" 
replace treated=1 if regione=="PIEMONTE" 
replace treated=1 if regione=="TRENTINO ALTO ADIGE" 
replace treated=1 if regione=="UMBRIA" 
replace treated=1 if regione=="VALLE D`AOSTA" 
replace treated=1 if regione=="VENETO" 
*creo un interazione tra tempo e trattamento. la chiamiamo did
gen did = post*treated
*stimo lo stimatore did
reg totale_pl1k_reg post treated did
*il coefficente did è l'effetto medio del trattamento sui trattati
*nel nostro caso il trattamento ha un effetto non significativo
*se non vanno i grafici successivi installare questo pacchetto
*ssc install lgraph 
*creiamo un grafico di confronto dell'outcome nei divversi anni presenti nel file
preserve 
collapse (mean) totale_pl1k_reg ,by(anno treated) 
lgraph totale_pl1k_reg anno , by(treated) xline(2015)
restore 
*possiamo anche fare la stessa cosa usando il comando diff
*installa il pacchetto se non va il comando sotto
*ssc install diff
diff totale_pl1k_reg, t(treated) p(post)
*anche questo comando ci dice che il decreto ministeriale non ha cambiato significativamente la situazione
encode regione, gen(regione_numeric)
didregress (totale_pl1k_reg) (did), group(regione_numeric) time(anno)
*anche qui il decreto non ha effetto
estat trendplots
estat ptrends
*testiamo anche assunzione di trend lineari paralleli
*poiche il p-value non è < 0.05 non possiamo rifiutare l'ipotesi nulla (H0: i trend lineari sono paralleli)
*ciò indica che l'assunzione di trend paralleli è soddisfatta




*Differences-in-Differences
use "C:\Users\paren\Desktop\_MAGISTRALE\ValutazioneSistemiSanitari\Stata\presentazione\dati.dta", clear
* Generiamo come prima cosa la variabile post , in base all'anno di uscita del decreto ministeriale
gen post=(anno>=2015)
*il treatment è totale_pl1k_in_eccesso
*creo una variabile che identifichi trattati e non trattati
*per noi quelli trattati sono quelli con posti letto in eccesso ovvero sopra 3.7 nel 2014
gen treated = 0
replace treated=1 if regione=="EMILIA ROMAGNA" 
replace treated=1 if regione=="LOMBARDIA"
replace treated=1 if regione=="MOLISE" 
replace treated=1 if regione=="PIEMONTE" 
replace treated=1 if regione=="TRENTINO ALTO ADIGE" 
replace treated=1 if regione=="VALLE D`AOSTA" 
*creo un interazione tra tempo e trattamento. la chiamiamo did
gen did = post*treated
*stimo lo stimatore did
reg totale_pl_riab1k_reg post treated did
*il coefficente did è l'effetto medio del trattamento sui trattati
*nel nostro caso il trattamento ha un effetto non significativo
*se non vanno i grafici successivi installare questo pacchetto
*ssc install lgraph 
*creiamo un grafico di confronto dell'outcome nei divversi anni presenti nel file
preserve 
collapse (mean) totale_pl_riab1k_reg ,by(anno treated) 
lgraph totale_pl_riab1k_reg anno , by(treated) xline(2015)
restore 
*possiamo anche fare la stessa cosa usando il comando diff
*installa il pacchetto se non va il comando sotto
*ssc install diff
diff totale_pl_riab1k_reg, t(treated) p(post)
*anche questo comando ci dice che il decreto ministeriale non ha cambiato significativamente la situazione
encode regione, gen(regione_numeric)
didregress (totale_pl_riab1k_reg) (did), group(regione_numeric) time(anno)
*anche qui il decreto non ha effetto
estat trendplots
estat ptrends
*testiamo anche assunzione di trend lineari paralleli
*poiche il p-value non è < 0.05 non possiamo rifiutare l'ipotesi nulla (H0: i trend lineari sono paralleli)
*ciò indica che l'assunzione di trend paralleli è soddisfatta


*https://libguides.princeton.edu/stata-did/1#s-lg-box-wrapper-37890613





















