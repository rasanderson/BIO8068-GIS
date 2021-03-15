# #
# # This is a Shiny web application. You can run the application by clicking
# # the 'Run App' button above.
# #
# # Find out more about building applications with Shiny here:
# #
# #    http://shiny.rstudio.com/
# #
# 
# library(shiny)
# 
# # Define UI for application that draws a histogram
# ui <- fluidPage(
# 
#     # Application title
#     titlePanel("Old Faithful Geyser Data"),
# 
#     # Sidebar with a slider input for number of bins 
#     sidebarLayout(
#         sidebarPanel(
#             sliderInput("bins",
#                         "Number of bins:",
#                         min = 1,
#                         max = 50,
#                         value = 30)
#         ),
# 
#         # Show a plot of the generated distribution
#         mainPanel(
#            plotOutput("distPlot")
#         )
#     )
# )
# 
# # Define server logic required to draw a histogram
# server <- function(input, output) {
# 
#     output$distPlot <- renderPlot({
#         # generate bins based on input$bins from ui.R
#         x    <- faithful[, 2]
#         bins <- seq(min(x), max(x), length.out = input$bins + 1)
# 
#         # draw the histogram with the specified number of bins
#         hist(x, breaks = bins, col = 'darkgray', border = 'white')
#     })
# }

library(shiny)
library(raster)
library(leaflet)
library(leafem)

pan50m <- raster("gis_data/pan50m.tif")
ll_crs <- CRS("+init=epsg:4326")
pan50m_ll <- projectRaster(pan50m, crs=ll_crs)

ui <- fluidPage(
    leaflet() %>% 
        addTiles(group = "OSM (default)") %>% 
        addProviderTiles(providers$Esri.WorldImagery, group = "Satellite") %>% 
        addRasterImage(pan50m_ll, colors=terrain.colors(25), group = "Elevation North Pennines") %>% 
        addLayersControl(
            baseGroups = c("OSM (default)", "Satellite"), 
            overlayGroups = "Elevation North Pennines",
            options = layersControlOptions(collapsed = FALSE)
        )
)
    
server <- function(input, output, session){
    map = createLeafletMap(session, 'map')
    
    observe({
        click<-input$map_click
        if(is.null(click))
            return()
        text<-paste("Lattitude ", click$lat, "Longtitude ", click$lng)
        map$showPopup( click$lat, click$lng, text)
    })
}


# Run the application 
shinyApp(ui = ui, server = server)
