using LumiraGadfly 
using Gadfly
using Base.Test

plot = plot([sin, cos], 0, 25)

exportToSVG(plot)

setId("trigo")
setName("HelloWorld")

@test getId() == "trigo"
@test getName() == "HelloWorld"