using Lumira
using Gadfly

plot = plot([x -> 2*sqrt(x),x -> -2*sqrt(x)],0,25)

exportToSVG(plot)

setId("comsapsbcd90helloworld")
setName("HelloWorld")
createLumiraExtension()