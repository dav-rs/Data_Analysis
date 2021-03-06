library(rstudioapi)

library(ggplot2)
#library(shiny)
#install.packages('shinythemes')
library(shinythemes)
library(dplyr)
#install.packages('splitstackshape')
library(splitstackshape)
library(leaflet)

## ________READING SOME DATA CSV FILES_______________
accidents <- read.csv('accidents.csv')
accid.edu.month <- read.csv('acci_edu_months.csv')
accid.edu <- read.csv('acci_edu.csv')
facts <- read.csv('facts.csv')
facts$fact <- as.character(facts$fact)

## ________LIBRARIES AND PREPROCESS FOR GRAPH 1 - CLOROPLETH_______________
# install.packages('choroplethr')
# install.packages('choroplethrMaps')
library(choroplethr)
library(choroplethrMaps)

## Reformat data to include columns region and value, required for choropleth func
accid.edu$region <- tolower(accid.edu$ST_NAME)
accid.edu$value <- accid.edu$fatalities
accid.edu$region <- gsub('_', ' ', accid.edu$region)

accid.edu.month$region <- tolower(accid.edu.month$ST_NAME)
accid.edu.month$value <- accid.edu.month$fatalities
accid.edu.month$region <- gsub('_', ' ', accid.edu.month$region)


ui <- shinyUI(fluidPage(theme = shinytheme("flatly"),
                        
                        # Application title
                        headerPanel("Traffic Fatalities in the US 2015"),
                        mainPanel(
                          tabsetPanel(
                            tabPanel("Home",
                                     sidebarPanel(
                                       sliderInput(inputId = "month_slider", label = "Month", min=0, max=12,value=0),
                                       selectInput("var_numcols", "Number of colors:", 
                                                   c("1" = "1",
                                                     "2" = "2",
                                                     "3" = "3",
                                                     "4" = "4"))
                                     ),
                                     actionButton("fact_btn", "Facts Button"),
                                     h4(textOutput("caption_fact"),style="color:coral"),
                                     h3(textOutput("caption1"),style="color:darkcyan"),
                                     plotOutput("choroPlot")),
                            tabPanel("Highways",
                                     sidebarPanel(
                                       selectInput("var_state", "State:", 
                                                   c("All"="All States",
                                                     "California" = "California",
                                                     "Florida" = "Florida",
                                                     "Texas" = "Texas")
                                       ),
                                       selectInput("var_interval", "Fatalities Interval:", 
                                                   c("More than 90" = "5",
                                                     "50 to 90" = "4",
                                                     "30 to 50" = "3",
                                                     "10 to 30"="2",
                                                     "More than 10" = "1")
                                       ),
                                       checkboxInput('label_box','Label Highway', FALSE)
                                     ),
                                     h5('Fact #9: The most dangerous Highways in the US are the I-10, I-5, US-101 and US-1 (althought they are interstate roads, the fatalities are present in the states of TX, CA and FL)',style="color:coral"),
                                     h5('Fact #10: Only Texas, California, and Florida have highways with more than 100 fatalities in 2015',style="color:coral"),
                                     h3(textOutput("caption4"),style="color:darkcyan"),
                                     leafletOutput("highPlot")),
                            tabPanel("Education",
                                     sidebarPanel(
                                       checkboxInput('drunk_box3','Drunk drivers', FALSE)
                                     ),
                                     h5('Fact #3: Around 25% of the fatalities are related to drunk drivers',style="color:coral"),
                                     h5('Fact #7: The states of Texas, California and Florida present some of the lowest performance in the SAT scores across the US',style="color:coral"),
                                     h5('Fact #8: A linear regression model shows that there is a relationship between the education performance and fatality rates while driving in the US. Can early education prevent irresponsible driving and higher fatalities?',style="color:coral"),
                                     h3(textOutput("caption3"),style="color:darkcyan"),
                                     plotOutput("eduPlot")),
                            tabPanel("Intersections",
                                     sidebarPanel(
                                       selectInput("var_hour", "Hour:", 
                                                   c("All"="All", "0" = "0", "1" = "1", "2" = "2",
                                                     "3" = "3", "4" = "4", "5" = "5",
                                                     "6" = "6", "7" = "7", "8" = "8",
                                                     "9" = "9", "10" = "10", "11" = "11",
                                                     "12" = "12", "13" = "13", "14" = "14",
                                                     "15" = "15", "16" = "16", "17" = "17",
                                                     "18" = "18", "19" = "19", "20" = "20",
                                                     "21" = "21", "22" = "22", "23" = "23")
                                       ),
                                       checkboxInput('drunk_box2','Drunk drivers', FALSE)
                                     ),
                                     h5('Fact #4: The higher fatal rate is Not at intersections followed by "Four-way intersections".',style="color:coral"),
                                     h5('Fact #5: There is a higher fatality rate between 10pm and 3 am',style="color:coral"),
                                     h5('Fact #6: Struck by falling cargo is the most reported cause of fatalities in Texas, California and Florida',style="color:coral"),
                                     h3(textOutput("caption2"),style="color:darkcyan"),
                                     plotOutput("interPlot"))
                          )
                        )
))


facts$fact[sample(nrow(facts),1)]

server <- shinyServer(function(input, output) {
  
  ## ________GRAPH 1 - CLOROPLETH GRAPH US FATALITIES_______________  
  observeEvent(input$fact_btn, {
    output$caption_fact <- reactiveText(function() {
      idx <- sample(nrow(facts),1)
      paste('Fact #',idx,':', facts$fact[idx])
    })
  })
  
  # Generate a choropleth plot for general overview
  output$choroPlot <- reactivePlot(function() {
    
    output$caption1 <- reactiveText(function() {
      ifelse(input$month_slider>0,paste("Overview fatalities for month: ", input$month_slider),"Overview fatalities for All year")
    })
    
    if (input$month_slider < 1) {
      p <- state_choropleth(accid.edu, 
                            title  = "US 2014 Traffic Fatalities", 
                            legend = "Fatalities", num_colors = as.numeric(input$var_numcols))
    } else {
      accid.edu2 <- accid.edu.month[accid.edu.month$MONTH==input$month_slider,]
      p <- state_choropleth(accid.edu2, 
                            title  = "US 2014 Traffic Fatalities", 
                            legend = "Fatalities", num_colors = as.numeric(input$var_numcols))
    }
    print(p)
  })
  
  ##  _________GRAPH 2 - ACCIDENTS MOST DANGEROUS STATES & INT. TYPE__________
  
  # Return the formula text for printing as a caption
  output$caption2 <- reactiveText(function() {
    paste("Fatalities per intersection type. Selected Hour: ", input$var_hour, "Hrs.")
  })
  
  accid.inters <- accidents[(accidents$ST_NAME==c('Texas','California','Florida')&
                               accidents$TP_INT_NAME!='Unknown' &
                               accidents$HOUR <=24),] %>%
    group_by(ST_NAME,TP_INT_NAME,HOUR) %>%
    summarise(fatalities = sum(FATALS),drunk_drivers=sum(DRUNK_DR)) 
  
  output$interPlot <- reactivePlot(function() {
    ifelse(input$var_hour=='All', accid.inters2 <- accid.inters[,],
           accid.inters2 <- accid.inters[accid.inters$HOUR==input$var_hour,])
    
    if (input$drunk_box2 == FALSE) { # Cases containing all drivers
      
      plt1 <- ggplot(accid.inters2,aes(TP_INT_NAME,fatalities,fill=ST_NAME))
      i <- plt1 + geom_bar(stat='identity',show.legend = FALSE)+facet_wrap(~ST_NAME)+
        coord_flip()+theme_minimal(base_size = 12)+ggtitle("Total Fatalities per Hour of day and Intersection type")
      print(i) }
    else { # Cases related to drunk drivers
      plt1 <- ggplot(accid.inters2,aes(TP_INT_NAME,drunk_drivers,fill=ST_NAME))
      
      plt1 + geom_bar(stat='identity',show.legend = FALSE)+facet_wrap(~ST_NAME)+
        coord_flip()+theme_minimal(base_size = 12)+ggtitle("Drunk drivers involved in fatalities per Hour of day")
    }
  })
  
  ## ________GRAPH 3 - EDUCATION VS DRUNK/TOTAL FATALITIES _______________________
  
  accid.edu$Group <- 'Others'
  accid.edu[(accid.edu$ST_NAME=='Florida')|(accid.edu$ST_NAME=='California')|
              (accid.edu$ST_NAME=='Texas'),]$Group <- 'Most_dangerous_states'
  
  labels <- c('Texas','California','Florida')
  labels2 <- c('Delaware','Idaho')
  labels3 <- c('District_of_Columbia')
  
  output$caption3 <- reactiveText(function() {
    paste("Reading score vs. Fatalities per state")
  })
  
  output$eduPlot <- reactivePlot(function() {
    if (input$drunk_box3 == FALSE) {
      # base layer reading score vs fatalities
      plt1 <- ggplot(accid.edu,aes(Critical.reading.score, fatalities,
                                   color=Group))
      # add geom_points by state
      e <- plt1 + geom_point()+theme_minimal(base_size = 14)+
        geom_text(aes(label = ST_NAME),
                  color = "coral", size = 5, hjust = -0.5,
                  data = accid.edu[accid.edu$ST_NAME %in% labels, ]) + 
        ggtitle("Reading scores vs Total Fatalities")
      print (e)
    } else {
      # base layer reading score vs drunk
      plt1 <- ggplot(accid.edu,aes(Critical.reading.score, drunk,
                                   color=Group, size=fatalities))
      # add geom_points by state
      e <- plt1 + geom_point()+theme_minimal(base_size = 14)+
        geom_text(aes(label = ST_NAME),
                  color = "coral", size = 4, hjust = -0.5,
                  data = accid.edu[accid.edu$ST_NAME %in% labels, ]) + 
        geom_text(aes(label = ST_NAME),
                  color = "black", size = 4, hjust = 1.2,
                  data = accid.edu[accid.edu$ST_NAME %in% labels2, ]) +
        geom_text(aes(label = ST_NAME),
                  color = "black", size = 4, hjust = -0.05,
                  data = accid.edu[accid.edu$ST_NAME %in% labels3, ]) +
        ggtitle("Reading scores vs Drunk drivers involved in fatality accidents")
      print(e)
    }
  })
  
  ## ______________GRAPH 4 - MAPS HIGHWAY AND FATALITIES _______________________
  
  output$caption4 <- reactiveText(function() {
    paste("Maps Highway and Fatalities for ", input$var_state)
  })
  
  cols<-c('LONGITUD','LATITUDE')
  accidents$COORDS <- do.call(paste,c(accidents[cols], sep='_'))
  
  accid.roads <- accidents %>%
    group_by(TWAY_ID,ST_NAME) %>%
    summarise(fatalities = sum(FATALS),drunk=sum(DRUNK_DR),
              coordinates=names(which.max(table(COORDS))))
  
  map_data <- accid.roads[accid.roads$fatalities>10,]
  
  map_data<-cSplit(map_data, "coordinates", sep = '_')
  colnames(map_data)[5] <- 'longitude'
  colnames(map_data)[6] <- 'latitude'
  
  # Remove rows with null values
  map_data <- map_data[-map_data$longitude>=0,]
  
  output$highPlot <- renderLeaflet({
    
    ifelse(input$var_state=='All States', map_data2 <- map_data,
           map_data2 <- map_data[map_data$ST_NAME==input$var_state,])
    
    ifelse(input$var_interval==1, map_data3<-map_data2[map_data2$fatalities>10,],
           ifelse(input$var_interval==2, map_data3 <-
                    map_data2[(map_data2$fatalities>10 & map_data2$fatalities<30),],
                  ifelse(input$var_interval==3,map_data3 <-
                           map_data2[(map_data2$fatalities>30 & map_data2$fatalities<50),],
                         ifelse(input$var_interval==4,map_data3 <-
                                  map_data2[(map_data2$fatalities>50 & map_data2$fatalities<90),],
                                map_data3 <- map_data2[map_data2$fatalities>90,]))))
    
    h <- leaflet(data=map_data3)%>%addTiles()%>%
      addMarkers(~longitude, ~latitude,
                 popup = ~as.character(paste(TWAY_ID,ST_NAME,'Fatalities: ',fatalities)),
                 label=~as.character(paste(TWAY_ID,ST_NAME,'Fatalities: ',fatalities)),
                 labelOptions=labelOptions(
                   noHide=input$label_box,direction='right'))
    print(h)
  })
  
})

shinyApp(ui,server)


