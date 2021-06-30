# social_reorientation
Code and data to reproduce the analyses reported in the manuscript: 

[Cosme et al. (Preprint) Testing the adolescent social reorientation model using hierarchical growth curve modeling with parcellated fMRI data](https://psyarxiv.com/8eyf5/)

## Compiled analysis files

The analyses reported in the main manuscript are reported [here](https://dsnlab.github.io/social_reorientation/analysis/main_analyses)

The analyses reported in supplementary material are reported [here](https://dsnlab.github.io/social_reorientation/analysis/main_analyses)


## Directory structure

* analysis = Contains the code to reproduce the analyses in the main manuscript and supplementary material
* data = Contains the data used in the analyses in the main manuscript and supplementary material
* mri = Contains the primary scripts used to preprocess and analyze the MRI data
* shiny_app = Contains the code to generate the shiny app hosted online at [https://dcosme.shinyapps.io/growth_curves/](https://dcosme.shinyapps.io/growth_curves/)

```
├── analysis
│ ├── clean_behavioral_data
├── data
├── mri
│	├── auto-motion
│	├── fx
│	├── parcellations
│	├── ppc
│	└── rx
│	    └── thresholding
│	        └── output
└── shiny_app
    └── growth_curves
        └── data
```
