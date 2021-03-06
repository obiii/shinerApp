
pakgs <- c("lubridate","shinydashboard","shinyalert","shinyWidgets","leaflet","leaflet.extras","dplyr","ggplot2")
lapply(pakgs, library, character.only = TRUE)

devtools::install_github("obiii/lab5", subdir="viser",  quiet = TRUE)
library(viser)


ui <- dashboardPage(
  dashboardHeader(title="Viser"),
  
  
  dashboardSidebar(
    
    # crime picker
    selectInput("crimes", "Choose Crime Type:",
                c("ALL" = 1,
                  "JUVENILE" = 2,
                  "DAMAGE"=3,
                  "SUDDEN"=4,
                  "LARCENY"=5,
                  "BURGLARY"=6,
                  "SEX"=7,
                  "MISSING"=8,
                  "DRIVING"=9,
                  "DRUGS"=10,
                  "LIQUOR"=11,
                  "MENTAL"=12,
                  "LOST"=13,
                  "FORGERY"=14,
                  "RECOVERED"=15,
                  "PUBLIC"=16,
                  "ASSAULT"=17,
                  "ROBBERY"=18,
                  "TRESPASSING"=19,
                  "FAMILY"=20,
                  "POLICE"=21,
                  "AUTO"=22,
                  "LITTERING"=23,
                  "OBSTRUCT"=24,
                  "SUICIDE"=25,
                  "FRAUD"=26,
                  "IDENTITY"=27,
                  "RAPE"=28,
                  "ATTEMPTED"=29,
                  "OVERDOSE"=30,
                  "WEAPON"=31,
                  "FUGITIVE"=32,
                  "ABDUCT"=33,
                  "ESCAPE"=34,
                  "EXTORT"=35,
                  "COUNTERFEITING"=36,
                  "TRAFFIC"=37,
                  "SOLICITATION"=38,
                  "STOLEN"=39,
                  "COMM"=40,
                  "UNAUTHORIZED"=41,
                  "EXTORTION"=42,
                  "ARSON"=43,
                  "KIDNAP"=44,
                  "LOITERING"=45,
                  "FIRE"=46,
                  "CARRYING"=47,
                  "THREAT"=48,
                  "PROPERTY"=49,
                  "EMBEZZLE"=50,
                  "INCOME"=51,
                  "HIT"=52,
                  "OBSCENE"=53,
                  "DRUNKENNESS"=54
                  )),
    #tableOutput("data")
    
   #year picker
    selectInput("years","Select Year:",c("2018","2017"),selected = "2018"),
    
    # check box
    switchInput(inputId = "switch",value=FALSE)
    
  ),
  
  dashboardBody(
    useShinyalert(),
    # ---------------------------- Values box KPIs
    fluidRow(
      valueBoxOutput("crime1"),
      
      # Dynamic valueBoxes
      valueBoxOutput("crime2"),
      
      valueBoxOutput("crime3")
    ),
    
    
    
    
   #-------------------------------------------- Main map box
   fluidRow(
     box(leafletOutput("map", height = 520), width = 12)
   ),
   
   # --------------------------------------- Graphs
   fluidRow(
     plotOutput("histo")
   )
  )
)


server <- function(input, output) {
  
  cur <- reactiveValues(dat=NULL)
  main <- reactiveValues(dat=NULL)
  
  # loading data
  data <- reactive({
    getLimitedData(limit = 500)
  })
  

  

  
  # --------------------- map
  
  output$map <- renderLeaflet({
    
    df <- data()
    main$dat <- df
    cur$dat <- df
    
    pal <- colorFactor(
      palette = 'Dark2',
      domain = data()$crimeType
    )
    
    m <- leaflet(data = df) %>%
      addTiles() %>%
      addCircleMarkers(lng = ~longitude,
                 lat = ~latitude,
                 popup = paste("Offense", df$crimeType, "<br>"),
                 color = ~pal(df$crimeType)
                 )
    m
  })
  
  observeEvent(input$years,{
    
    year <- input$years
    
    data <- cur$dat
    
    data <- data[year(data$date) == year,]

    if(nrow(data) >= 1){
      
      pal <- colorFactor(
        palette = 'Dark2',
        domain = data$crimeType
      )
      
      leafletProxy("map",data = data) %>%
        clearMarkers() %>%
        clearHeatmap()%>%
        addTiles() %>%
        addCircleMarkers(lng = ~longitude,
                         lat = ~latitude,
                         popup = paste("Offense", data$crimeType, "<br>"),
                         color = ~pal(data$crimeType)
        )
      
    }else{
      shinyalert("Oops!", paste0("No data for: ",input$years), type = "error")
    }
    
  })
  
  observeEvent(input$switch,{

    if(input$switch == TRUE){
  
      leafletProxy("map",data = cur$dat) %>%
      clearMarkers()%>% addProviderTiles(providers$CartoDB.DarkMatter) %>%
        addHeatmap(lng=~longitude, lat=~latitude, intensity = ~victims, blur = 20, max = 0.05, radius = 15)
        
      
    }else if(input$switch == FALSE){

      
      pal <- colorFactor(
        palette = 'Dark2',
        domain = cur$dat$crimeType
      )
      
      
      leafletProxy("map",data = cur$dat) %>%
        clearMarkers() %>%
        clearHeatmap()%>%
        addTiles() %>%
        addCircleMarkers(lng = ~longitude,
                         lat = ~latitude,
                         popup = paste("Offense", cur$dat$crimeType, "<br>"),
                         color = ~pal(cur$dat$crimeType)
        )
    }
    
  })
  


  observeEvent(input$crimes,{
    
    ctype <- input$crimes
    df <- data()
   
    
    if(ctype ==1){
      df <- df
    }else{
      
      df <- getDataByCrimeType(df,as.numeric(ctype))
    }
    cur$dat <- df

    
    if(nrow(cur$dat) >=1 ){
      pal <- colorFactor(
        palette = 'Dark2',
        domain = df$crimeType
      )
      leafletProxy("map",data = df) %>%
        clearMarkers() %>%
        addTiles() %>%
        addCircleMarkers(lng = ~longitude,
                         lat = ~latitude,
                         popup = paste("Offense", df$crimeType, "<br>"),
                         color = ~pal(df$crimeType)
        )
      
      crime <- getCrimeByID(ctype)
      # histogram logic
      ID <- 1:12
      output$histo <-renderPlot({
        p<- df %>%
          mutate(mon =month(df$date)) %>%
          select(crimeType, mon)%>%
          group_by(mon,crimeType) %>%
          summarize(total = n()) %>%
          ggplot(aes(x = mon, y = total,fill=crimeType)) + geom_bar(stat = "identity") + 
          ggtitle("Crimes in all months")+
          ylab("Crime Count")+
          scale_x_continuous("Months", labels = as.character(ID), breaks = ID)
        p
      })
      
    }else{
      shinyalert("Oops!", "No data found ", type = "error")
    }
  })
  
  
  # --------- graphs
  output$crime1 <- renderValueBox({
    
    df <- data()

    df <- as.data.frame(df %>% group_by(crimeType) %>% summarise(Value = n()))
    df <- df[order(df$Value,decreasing = TRUE),]
    df <- df[1:3,]
    main$dat <- df
    
    valueBox(
      paste0(as.character(df[1,][1])," - ", as.character(df[1,][2])), "Highest", icon = icon("list"),
      color = "red"
    )
  })
  
  output$crime2 <- renderValueBox({
    valueBox(
      paste0(as.character(main$dat[2,][1])," - ", as.character(main$dat[2,][2])), "2nd", icon = icon("list"),
      color = "orange"
    )
  })
  output$crime3 <- renderValueBox({
    valueBox(
      paste0(as.character(main$dat[3,][1])," - ", as.character(main$dat[3,][2])), "3rd", icon = icon("list"),
      color = "yellow"
    )
  })
  
}
shinyApp(ui, server)