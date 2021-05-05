# Simple demonstration of interactive viewshed calculation
library(shiny)
library(sf)
library(raster)
library(leaflet)
library(leafem)
library(rgdal)
source("LOS.R")

pan50m <- raster("www/elevation.tif")
pan500m <- aggregate(pan50m, fact=10) # aggregate to 500m grid for speed

pan500m[is.na(pan500m[])] <- 1

ll_crs <- CRS("+init=epsg:4326")
pan50m_ll <- projectRaster(pan50m, crs=ll_crs)

ui <- fluidPage(
    leafletOutput(outputId = "map")
)
    
server <- function(input, output, session){
    # Display basemap of terrain
    output$map <- renderLeaflet({
        leaflet() %>%
            setView(lng = -3.0886, lat=54.4609, zoom=9) %>%
            addRasterImage(pan50m_ll, colors=terrain.colors(25))
    })
    
    # Detect a click event and grab coordinates for viewshed
    observeEvent(input$map_click, {
        coord <- input$map_click
        lng <- coord$lng 
        lat <- coord$lat

        # Create a sf points feature in latitude longitude 4326, and project back to OS 2770
        # The if(length(c(lng,lat))) needed as when Shiny starts there is no data here
        # so would otherwise give an error. On clicking the map, the lng and lat recorded
        if(length(c(lng,lat))==2){
            turbine_pt_ll <- data.frame(lat = lat, lng = lng) %>% 
                st_as_sf(coords = c("lng", "lat")) %>% 
                st_set_crs(4326)
            turbine_pt_os <- st_transform(turbine_pt_ll, crs=27700)
            turbine_pt_os <- st_geometry(turbine_pt_os)[[1]] # Only want geometry

            # Calculate 5km viewshed and reproject back to lat-lon
            viewshed_5km_os <- viewshed(dem=pan500m, windfarm=turbine_pt_os,
                                        h1=1.5, h2=50, radius=5000)
            viewshed_5km_ll <- projectRaster(viewshed_5km_os, crs=ll_crs)

            # Add to existing map            
            leafletProxy("map") %>% 
                addRasterImage(viewshed_5km_ll, color="red")
        }
    })
}

# Run the application 
shinyApp(ui = ui, server = server)
