
library(data.table)
library(sp)
library(rgdal)
library(ggplot2)
library(ggmap)
library("rnaturalearth")
library("rnaturalearthdata")
library("rnaturalearthhires")

#leer base
chi_dat = fread("CommAreas.csv")
View(chi_dat)
# this sets your google map for this session
register_google(key = "[AIzaSyA9cciGSTlaNkq0d7CPxwON1PF7vE-O5AY]"
                ,write = TRUE)

chi_dat = as.data.table(chi_dat)
chi_tab = chi_dat[COMMUNITY!=""]

world <- ne_countries(scale = "medium", returnclass = "sf")
class(world)

#Datos
Base_ejemplo1<-Base_ejemplo
coordinates(Base_ejemplo1) = c("longitud","latitud")
crs.geo1 = CRS("+proj=longlat")
proj4string(Base_ejemplo1)=crs.geo1
misDatos <- data.frame(Base_ejemplo1)

ggplot(data = world) +
  geom_sf() +
  geom_point(data = misDatos, aes(x = longitud, y = latitud), size = 2, 
             shape = 23, fill = "darkred") +
  coord_sf(xlim = c(-105, -95), ylim = c(16, 22), expand = FALSE)



