library(shiny)

# Define UI for application that draws a histogram
shinyUI(fluidPage(
  
  # Application title
  titlePanel("Genetic Lifespan Explorer"),
  
  # Sidebar with a slider input for number of bins 
  sidebarLayout(
    sidebarPanel(
      
      a("Skene, Roy, and Grant (2017)", 
        href="https://www.ncbi.nlm.nih.gov/pmc/articles/PMC5595438/"),
      
      "quantified gene expression in mouse
      hippocampi sampled across the lifespan. This app allows researchers to
      explore the dataset and query the age dependent variation in the expression 
      of their favorite genes.",
      
      tag("br", ""),
      
      textInput("caption", "Enter Gene Names", "SEMA4D, PLXNB1, CD72, GAPDH"),
      
      "Enter up to ten gene names sperated by commas. 
      Names must be valid mouse gene abbreviations.",
      
      tag("br", ""),
      
      submitButton(text = "Go", icon = NULL, width = NULL),
      
      radioButtons("chart_type", NULL, choices = c(
        "Lifespan charts", "Correlation matrix", "Predictivity charts"
      ), selected = "Lifespan charts")
      
    ),
    
    # Show a plot of the generated distribution
    mainPanel(
      plotOutput("Plot", height="500px"),
      
      tag("br", ""),
      
      "`Lifespan charts` will show gene expression trends across all sampled ages.
      `Correlation matrix` will show the linear dependencies and heirarchical clustering
      of genes across the lifespan. `Predictivity charts` will show the result of fitting
      a random forest regressor to total-RNA-normalized and z-scored expression data for the 
      given genes with animal age as the outcome variable. The dataset is randomly partitioned 
      into training and testing sets, and the displayed fitted values correspond to the testing set."
    )
  )
))


