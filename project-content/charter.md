# Project charter

## 1. Project context

### 1.1. Context on the operational process and current gap

Using alternative data as a source in lower level aggregation complicates the regular task National Statistical Offices (NSOs) face in understanding and explaining price movements within the overall CPI. This is due in part simply to the scale of the data processed (hence a larger number of potential trends to keep an eye on), as well as the numerous data disruptions to the data that may occur (potentially affecting the measurement). This is made even harder when the NSO applies multilateral price index methods, as data from multiple time periods within a window is included to measure price change, expanding the complex set interdependencies that must be evaluated and tracked over (i.e. many more data points and sub-trends need to be analyzed). 

A considered approach is thus required to develop a robust suite of diagnostic and analytical outputs that enable an NSO to operationalize alternative data in a mature fashion and be confident why the output is what it is, most especially with multilateral methods. Specifically, a set of input diagnostics is needed to track possible data issues with raw and interim data (i.e. tracking various forms of disruption or corruption that may impact specific steps in the price measurement process), as well as analytical outputs that explain the price movement in terms of contributions (of individual products or sub-groups of products/services).

In essence – production staff in various NSOs CPI groups need to ‘use windows in the black box’ to validate that everything is operating as it should, as well as to understand and explain the source of inflation as part of the dissemination process, ensuring that trust and transparency in the overall publication is maintained. To the knowledge of the project team, literature on the topic is limited and little guidance is available to NSOs on how to do this.

This project researches this to support NSOs developing this critical operational task. It focuses on defining and testing a set of diagnostic and analytical outputs that can provide a detailed picture of most of the critical concerns for CPI compilers. 

### 1.2. Project value add

This key operational topic is currently not defined in a formalized way, leaving NSOs to figure out how to apply it themselves. Due to resource constraints or lack of training, that may mean various diagnostic considerations are not considered or paid attention to. Analytics may focus on the key diagnostic tools (if at all) – hence the ability to fully understand the source of inflation may be compromised. 

The project aims to support NSOs by:

-   Starting the scientific discussion of formally defining what is key and the likely ‘sensible defaults’ to pay attention to. Openness and reproducibility are key to support the peer review and confirmation of the diagnostics and analytics that are needed.

-   Demonstrating the application of developed diagnostic and analytic tools on open data – acting as a ‘teaching and explanation aid’ to NSOs looking to understand and apply them. 

-   Provide the code to operationalize the developed diagnostics and analytics so that NSOs can adopt this with a low overhead (import and use a package that is well defined and explained).

## 2. Project Objectives

### 2.1. Project goals/deliverables

The objective of the research is to:

-   [ ] Outline the what to look for in input data that may impact measurement. For instance:

    -   What to look out for in raw data an NSO would receive regularly -- such as comprehensiveness in the data being received; key variables missing/change; excessive overall churn, etc.  

    -   What to look out for in input data to the price calculation step -- such as: post-classification it is found that some categories have excessive churn; etc

-   [ ] Define a set of analytical diagnostics that are key understanding and explaining price movement in the context of multilateral methods. For instance:

    -   Summary input data quality charts that may be useful for analytic purposes.

    -   How to decompose the overall movement into contributions of various sub-strata (e.g. that have exited/entered the sample, as well as those that remain), to understand what in the composition of the market is driving the movement.

    -   If quality change is occurring in the sample and the role it has on the movement (if quality adjustment methods are used). For instance if the composition of products of a certain quality or having certain characteristics is shifting.

-   [ ] Validate and demonstrate the analytical outputs on a set of open data that mimics real world scenarios in the form of a digestible site with interactive dashboards. Publish the processing code and detailed processing logic openly (the project should be fully reproducible) so that other price statisticians can assess and validate the approach, and NSOs know exactly how to operationalize these diagnostics and analytics.

-   [ ] Write a detailed paper to present the findings for peer review at an upcoming price statistics conference (e.g. Ottawa Group meeting, or ILO/IMF/World Bank/Eurostat Price Statistics Conference).

### 2.2. Objectives not in scope

-   To develop comprehensive dashboards and diagnostics. Apply the 80-20 rule in determining a 'sensible default set'

-   Trial all multilateral methods. NSOs typically use a small subset, hence to provide most value, focus only on common methods.

## Project team

| Name             | Role                            |
|------------------|---------------------------------|
| Frances Krsinich | Researcher, methodological lead |
| Serge Goussev    | Researcher, technical lead      |

: Project team

## Milestones

The following high level milestones summarize key phases of the project. Detailed sub-tasks are [managed in the GitHub project](https://github.com/users/sergegoussev/projects/4/views/1?layout=table) with milestones to track work according to each.

-   [Project definition/planning](https://github.com/sergegoussev/multilateral-diagnostics/milestone/1) - finalize the project scope, submit an abstract, confirm DMP, etc

-   [Project setup](https://github.com/sergegoussev/multilateral-diagnostics/milestone/2) - setup compendium, develop end-to-end skeleton process

-   Data acquisition - admin steps to select and acquire (if needed) other data for the project

-   Expand analysis (to other methods/datasets) - flush out the end-to-end skeleton with additional datasets and methods

-   Finalize research objects for OG2026 - finalize paper, prep presentation, polish project site and visual examples