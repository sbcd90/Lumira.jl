using Lumira 
using Gadfly
using Base.Test


plot = plot([sin, cos], 0, 25)

setToWriteToFile(false) 

exportToSVG(plot)

setId("trigo")
setName("HelloWorld")

@test getId() == "trigo"
@test getName() == "HelloWorld"
@test createTemplate("dummyPath") == true
@test createChartCode("dummyPath") == true
@test createLumiraExtension() == true