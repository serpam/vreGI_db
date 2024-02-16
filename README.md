
# <span style="color:#43839f">vreGI:</span> Virtual Research Environment Grazing Intensity <img src="app/vregi/www/logo_vreGI.png" align="right" width="240"/>


<!-- badges: start -->
[![DOI](https://zenodo.org/badge/457682829.svg)](https://zenodo.org/badge/latestdoi/457682829)
<!-- badges: end -->


This repo contains the information with an application that visualizes livestock movement data from different livestock farms located in several natural areas of Andalusia. Different GPS devices (n = 96) have been installed in 16 livestock farms, mainly sheep, but also goats and cows. Different tracking technologies (sigfox, gsm, satellite and continuous measurement) were used and the movement of the animals was monitored since February 2022. These devices have been installed in the framework of the project [SUMHAL](https://lifewatcheric-sumhal.csic.es/) (*Sustainability for Mediterranean Hotspots in Andalusia integrating LifeWatch ERIC*), specifically in the subprojects LWE2103026 and LWE210303027 that focus on analysing the role of traditional silvopastoral practices in the biodiversity of ecosystems and in the prevention of forest fires in natural areas of Andalusia, for which it will be supported by updated technological tools. These sub-projects are being carried out by the Service for the Evaluation, Restoration and Protection of Mediterranean Agrosystems ([SERPAM](https://serpam.csic.es/)) of the [Estación Experimental del Zaidin](https://www.eez.csic.es/), of the CSIC. 

The data were collected using a semi-automatic procedure, filtered for quality and integrated into a SQL database. They were then integrated into movebank, a movement data repository (movebank ID = [3088763011](https://www.movebank.org/cms/webapp?gwt_fragment=page=studies,path=study3088763011)), and this interactive application was generated for their visualisation. 


### How it works?

1. You can run the live app in this [link](https://eez-csic.gvsigonline.com/shiny/sumhal/vregi/) 

2. You also could donwload the repo, and run the app inside Rstudio. For this purpose, after the donwload the repository and unzziped it, run the file `app.R` 

```r
source("./app/app.R") 
```


### Credits <sup><a href="#fn1" id="ref1">1</a></sup>

-   [**Antonio J. Pérez-Luque**](https://github.com/ajpelu) <a href="https://orcid.org/0000-0002-1747-0469" target="orcid.widget"> <img src="https://info.orcid.org/wp-content/uploads/2019/11/orcid_16x16.png" alt="ORCID logo" width="16" height="16"/></a>: Conceptualization, Data curation, Methodology, Software, Validation, Visualization. 

-   **Mauro J. Tognetti Barbieri**: Data curation, Methodology, and Validation.

-   **Maria Eugenia Ramos Font** <a href="https://orcid.org/0000-0002-4888-0401" target="orcid.widget"> <img src="https://info.orcid.org/wp-content/uploads/2019/11/orcid_16x16.png" alt="ORCID logo" width="16" height="16"/></a>: Funding acquisition and Resources.

-   **Ana Belén Robles Cruz** <a href="https://orcid.org/0000-0002-1353-2917" target="orcid.widget"> <img src="https://info.orcid.org/wp-content/uploads/2019/11/orcid_16x16.png" alt="ORCID logo" width="16" height="16"/></a>:Funding acquisition, Project administration, and Resources.


<sup id="fn1">1. ([CRedIT](https://credit.niso.org/) Statment)<a href="#ref1" title="Jump back to footnote 1 in the text.">↩</a></sup>


### Developer: 
- [**Antonio J. Pérez-Luque**](https://github.com/ajpelu) <a href="https://orcid.org/0000-0002-1747-0469" target="orcid.widget"> <img src="https://info.orcid.org/wp-content/uploads/2019/11/orcid_16x16.png" alt="ORCID logo" width="16" height="16"/></a> 

### Project
* This study was funded by MICINN through European Regional Development Fund SUMHAL, LIFEWATCH-2019-09-CSIC-13, POPE 2014-2020. More info about the [SUMHAL](https://lifewatcheric-sumhal.csic.es/) project (Sustainability for Mediterranean Hotspots in Andalusia integrating LifeWatch ERIC).

### How to cite: 
Pérez-Luque, A.J.; Tognetti Barbieri, M.J.; Ramos-Font, M.E.; Robles-Cruz, A.B. (2023). vreGI virtual Research Environment Grazing Intensity: Monitoring grazing patterns in Andalusia Natural protected areas. https://github.com/serpam/vreGI_db. version 1.0. doi: [10.5281/zenodo.7347993](https://doi.org/10.5281/zenodo.7347993) 

```
@misc{PerezLuque2023,
	title        = {vreGI: virtual Research Environment Grazing Intensity: Monitoring grazing patterns in Andalusia Natural protected areas},
	author       = {Pérez-Luque, Antonio Jesús and Toggnetti Barbieri, Mauro José and 
	                Ramos-Font, Maria Eugenia and Robles Cruz, Ana Belén},
	year         = {2023},
	url          = {https://github.com/serpam/vreGI_db},
	version      = {1.0}
	doi          = {10.5281/zenodo.8402099}
}

```
