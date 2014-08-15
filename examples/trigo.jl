using Lumira
using Gadfly

plot = plot([sin,cos], 5, 25)

exportToSVG(plot)

setId("trigo")
setName("HelloWorld1")
createLumiraExtension()