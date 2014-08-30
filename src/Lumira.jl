module Lumira

# package code goes here
using Gadfly
using Base.show

export setId,setName,getId,getName,setToWriteToFile,exportToSVG,createTemplate,createChartCode,createLumiraExtension

type LumiraExtension
    Id::String
    Name::String
end

type flagToWriteToFile
    flag::Bool
end    

extn = LumiraExtension("","") 
fileotpt = flagToWriteToFile(true)

function setId(identifier)
	extn.Id = identifier
end

function setName(name)
    extn.Name = name
end

function getId()
    extn.Id
end

function getName()
    extn.Name
end

function setToWriteToFile(flag)
    fileotpt.flag = flag
end      

function exportToSVG(plot)
    draw(SVG("tempplot.svg",22cm ,16cm), plot)
end  

#use this function to create SAP Lumira Extension

function createLumiraExtension()
    if extn.Id != "" && extn.Name != ""
        folderloc = extn.Id
        commandList = ""
        commandList = string(commandList,"mkdir $folderloc","\ncd $folderloc","\nmkdir bundles","\ncd bundles")
        
        IdStr = extn.Id
        folderPath = ""
        pathFormer = ""
        
        for count = 1:endof(IdStr)
            if IdStr[count]=='.'
                commandList = string(commandList,"\nmkdir $folderPath","\ncd $folderPath")
                pathFormer = string(pathFormer,folderPath,"/")
                folderPath = ""
            else
                folderPath = string(folderPath,IdStr[count])
            end    
        end
        commandList = string(commandList,"\nmkdir $folderPath","\ncd $folderPath")
        commandList = string(commandList,"\nmkdir resources","\ncd resources","\nmkdir templates","\ncd templates","\nmkdir sample","\ncd sample")
        
        pathFormer = string(pathFormer,folderPath,"/")
        templatePathFormer = string("resources/","templates/","sample/")
        
        if fileotpt.flag==true
            file = open("createFolderStruct.bat","w")
            write(file,commandList)
            close(file)
        else
            return true
        end
        
        run (`createFolderStruct.bat`)
        run (`rm createFolderStruct.bat`)
        createChartCode(string(extn.Id,"/","bundles","/",pathFormer,folderPath,"-bundle.js"))
        createTemplate(string(extn.Id,"/","bundles","/",pathFormer,templatePathFormer,"template.js"))
        
        run(`rm tempplot.svg`)
    end
end

function parseXML()
    if isfile("tempplot.svg")
        file = open("tempplot.svg")
        lines = readlines(file)
        close(file)
        
        finalArr = String[]
        push!(finalArr,"<svg")
        newCount = 0
        
        for count = 5:length(lines)
            line = chomp(lines[count])
            newline = ""
            flag = 0
            for index = 1:length(line)
                if line[index]=='\'' && flag==0
                    newline = string(newline,"' + \"'")
                    flag = 1
                elseif line[index]=='\'' && flag==1
                    newline = string(newline,"'\" + '")
                    flag = 0
                else
                    newline = string(newline,line[index])
                end
            end    
            push!(finalArr,newline)
            newCount = newCount + 1
        end
        
        finalArr            
    end    
end

function createChartCode(folderPath)
    if fileotpt.flag==true
        file = open(folderPath,"w")
    end     
    
    jsCodeString = string("(function() {",
"    /**",
"     * This function is a drawing function; you should put all your drawing logic in it.\n",
"     * it's called in moduleFunc.prototype.render\n",
"     * @param {Object} data - data set passed in\n",
"     * @param {SVG Group} vis - canvas which is an svg group element\n",
"     * @param {float} width - width of canvas\n",
"     * @param {float} height - height of canvas\n",
"     * @param {Array of color string} colorPalette - color palette\n",
"     * @param {Object} properties - properties of chart\n",
"     * @param {Object} dispatch - event dispatcher\n",
"     */\n",
"    function render(data, vis, width, height, colorPalette, properties, dispatch) {\n",
"        document.getElementsByTagName(\"head\")[0].innerHTML = document.getElementsByTagName(\"head\")[0].innerHTML + '<script type=\"text/javascript\"' + \n", 
"'src=\"http://canvg.googlecode.com/svn/trunk/rgbcolor.js\"></script><script type=\"text/javascript\" src=\"http://canvg.googlecode.com/svn/trunk/StackBlur.js\">'+ \n",       "  '</script><script type=\"text/javascript\" src=\"http://canvg.googlecode.com/svn/trunk/canvg.js\"></script>'; \n",
"        document.getElementsByClassName(\"viz-controls-chart-layer\")[0].innerHTML = '<canvas id=\"canvas\"></canvas>';\n",
"        canvg(document.getElementById('canvas'),")

    svgReturned = parseXML()
    
    for count = 1:(length(svgReturned)-1)
        jsCodeString = string(jsCodeString,"'",svgReturned[count],"' +\n")
    end
    jsCodeString = string(jsCodeString,"'",svgReturned[length(svgReturned)],"'\n")
    
    jsCodeString = string(jsCodeString,");")
    
    jsCodeString = string(jsCodeString,"\n}\n",
"\n",
"\n",
"    /*------------------------------------------------------------------------*/\n",
"\n",
"    /*\n",
"     * In most cases, you don't need to modify the following code.\n",
"     */\n",
"\n",
"    var _util = {/*__FOLD__*/\n",
"        mapping : {\n",
"            dses : [],\n",
"            mses : []\n",
"        },\n",
"        /**\n",
"         * extract dimension sets from data\n",
"         * @param data [Crosstable Dataset] crosstable dataset\n",
"         * @returns array of dimension sets, and each dimension set is an object of {dimension: \"dimension name\", data: [members]}.\n",
"         * e.g. [{dimension: 'country', data: ['China', 'US', ...]}, {dimension: 'year', data: ['2010', '2011', ...]}, ...]\n",
"         */\n",
"        extractDimSets : function(data) {\n",
"            var dimSet1, dimSet2, res = [];\n",
"            if (data.getAnalysisAxisDataByIdx) {\n",
"                dimSet1 = data.getAnalysisAxisDataByIdx(0);\n",
"                dimSet2 = data.getAnalysisAxisDataByIdx(1);\n",
"            } else if (data.dataset && data.dataset.data) {\n",
"                data.dataset.data().analysisAxis.forEach(function(g){\n",
"                    var resg = [];\n",
"                    g.data.forEach(function(d){\n",
"                        var length = d.values.length;\n",
"                        var result = {};\n",
"                        result.data = [];\n",
"                        for(var i in d.values){\n",
"                            result.data[i] = d.values[i];\n",
"                        };\n",
"                        result.dimension = d.name;\n",
"                        resg.push(result);\n",
"                    });\n",
"                    res.push(resg);\n",
"                });\n",
"                return res;\n",
"            };\n",
"\n",
"            ",'\u0024',".each([dimSet1, dimSet2], function(idx, dimSet) {\n",
"                dimSet = dimSet ? dimSet.values : undefined;\n",
"                if (!dimSet)\n",
"                    return;\n",
"                var dims = [], dim;\n",
"                for (var i = 0; i < dimSet.length; i++) {\n",
"                    dim = {\n",
"                        dimension : dimSet[i].col.val,\n",
"                        data : []\n",
"                    };\n",
"                    for (var j = 0; j < dimSet[i].rows.length; j++)\n",
"                        dim.data.push(dimSet[i].rows[j].val);\n",
"                    dims.push(dim);\n",
"                }\n",
"                res.push(dims);\n",
"            });\n",
"            return res;\n",
"        },\n",
"        /**\n",
"         * extract measure sets from data\n",
"         * @param data [Crosstable Dataset] crosstable dataset\n",
"         * @returns array of measures, and each measure is an object of {measure: \"measure name\", data: [measure data]}.\n",
"         * for example, [[{measure: 'income', data: [555, 666, 777, ...]}, {measure: 'cost', data:[55, 66, 77, ...]}, ...], ...]\n",
"         */\n",
"        extractMeasureSets : function(data) {\n",
"\n",
"            var measureSet1, measureSet2, measureSet3, reses = [];\n",
"            if (data.getMeasureValuesGroupDataByIdx) {\n",
"                measureSet1 = data.getMeasureValuesGroupDataByIdx(0);\n",
"                measureSet2 = data.getMeasureValuesGroupDataByIdx(1);\n",
"                measureSet3 = data.getMeasureValuesGroupDataByIdx(2);\n",
"            }\n",
"            else if (data.dataset && data.dataset.data) {\n",
"                data.dataset.data().measureValuesGroup.forEach(function(g){\n",
"                    var resg = [];\n",
"                    g.data.forEach(function(d){\n",
"                        var length = d.values.length;\n",
"                        var result = {};\n",
"                        result.data = [];\n",
"                        for (var i in d.values) {\n",
"                            result.data[i] = d.values[i];\n",
"                        };\n",
"                        result.measure = d.name;\n",
"                        resg.push(result);\n",
"                    });\n",
"                    reses.push(resg);\n",
"                });\n",
"                return reses;\n",
"            };\n",
"\n",
"            ",'\u0024',".each([measureSet1, measureSet2, measureSet3], function(idx, measureSet) {\n",
"                measureSet = measureSet ? measureSet.values : undefined;\n",
"                if (!measureSet)\n",
"                    return;\n",
"                var res = [], resItem, resData, measure;\n",
"                for (var k = 0; k < measureSet.length; k++) {\n",
"                    measure = measureSet[k];\n",
"                    resItem = {\n",
"                        measure : measure.col,\n",
"                        data : []\n",
"                    };\n",
"                    resData = resItem.data;\n",
"                    for (var i = 0; i < measure.rows.length; i++) {\n",
"                        resData[i] = [];\n",
"                        for (var j = 0; j < measure.rows[i].length; j++) {\n",
"                            resData[i].push(measure.rows[i][j].val);\n",
"                        }\n",
"                    }\n",
"                    res.push(resItem);\n",
"                }\n",
"                reses.push(res);\n",
"            });\n",
"\n",
"            return reses;\n",
"        },\n",
"\n",
"        /**\n",
"         * convert crosstable data to flatten table data\n",
"         * @param data [Crosstable Dataset] crosstable dataset\n",
"         * @returns array of objects, and each object represents a row of data table:\n",
"         * [{\"dim set name\": [dim1 member, dim2 member, ...], ..., \"measure set name\": [measure1 value, measure2 value, ...]}, ...]\n",
"         * e.g. [{Time: ['2010', 'Jan'], Entity: ['China'], Profit: [555, 444]},  ...]\n",
"         *\n",
"         * In addition, the array has a meta data property; its name is meta.\n",
"         * It is an object with dim set name or measure set name as key,\n",
"         * and names of dims and names of measures as value:\n",
"         * {\"dim set name\": [dim1 name, dim2name, ...], ..., \"measure set name\": [measure1 name, measure2 name, ...], ...}\n",
"         * for example, {Time: ['Year', 'Month'], Entity: ['Country'], Profit: ['Gross Profit', 'Net Profit']}\n",
"         */\n",
"        toFlattenTable : function(data) {\n",
"            var dimSets = this.extractDimSets(data), measureSets = this.extractMeasureSets(data), fdata = [], datum, measure0Data, measure, me = this;\n",
"            //measureValueGroup is necessary in crosstable dataset\n",
"            //please directly call _util.extractDimSets() to get dimension values \n",
"            if (measureSets.length === 0) {\n",
"                return;\n",
"            }\n",
"            var i, j, k, m;\n",
"            //fill meta data\n",
"            fdata.meta = {};\n",
"            ",'\u0024',".each(dimSets, function(idx, dset) {\n",
"                if (!dset)\n",
"                    return;\n",
"                var name = me.mapping.dses[idx];\n",
"                fdata.meta[name] = dset.map(function(ele) {\n",
"                    return ele.dimension;\n",
"                });\n",
"            });\n",
"            ",'\u0024',".each(measureSets, function(idx, mset) {\n",
"                if (!mset)\n",
"                    return;\n",
"                var name = me.mapping.mses[idx];\n",
"                fdata.meta[name] = mset.map(function(ele) {\n",
"                    return ele.measure;\n",
"                });\n",
"            });\n",
"            //convert data from ct to flat\n",
"            measure0Data = measureSets[0][0].data;\n",
"            for ( i = 0; i < measure0Data.length; i++) {\n",
"                for ( j = 0; j < measure0Data[i].length; j++) {\n",
"                    datum = {};\n",
"                    ",'\u0024',".each(dimSets, function(idx, dimSet) {\n",
"                        if (!dimSet)\n",
"                            return;\n",
"                        var name = me.mapping.dses[idx];\n",
"                        var val = datum[name] = datum[name] || [];\n",
"                        var counter = idx === 0 ? j : i;\n",
"                        for ( m = 0; m < dimSet.length; m++) {\n",
"                            val.push(dimSet[m].data[counter]);\n",
"                        }\n",
"                    });\n",
"                    ",'\u0024',".each(measureSets, function(idx, measureSet) {\n",
"                        if (!measureSet)\n",
"                            return;\n",
"                        var name = me.mapping.mses[idx];\n",
"                        var val = datum[name] = datum[name] || [];\n",
"                        for ( m = 0; m < measureSet.length; m++) {\n",
"                            measure = measureSet[m];\n",
"                            val.push(measure.data[i][j]);\n",
"                        }\n",
"                    });\n",
"                    fdata.push(datum);\n",
"                }\n",
"            }\n",
"            return fdata;\n",
"        }\n",
"    };\n",
"\n",
"    (function() {/*__FOLD__*/\n",
"        // Drawing Function used by new created module\n",
"        var moduleFunc = {\n",
"            _colorPalette : d3.scale.category20().range().concat(d3.scale.category20b().range()).concat(d3.scale.category20c().range()), // color palette used by chart\n",
"            _dispatch : d3.dispatch(\"initialized\", \"startToInit\", 'barData') //event dispatcher\n",
"        };\n",
"\n",
"        moduleFunc.dispatch = function(_){\n",
"            if(!arguments.length){\n",
"                return this._dispatch;\n",
"            }\n",
"            this._dispatch = _;\n",
"            return this;\n",
"        };\n",
"\n",
"        //a temp flag used to distinguish new and old module style in manifest\n",
"\n",
"        /*\n",
"         * function of drawing chart\n",
"         */\n",
"        moduleFunc.render = function(selection) {\n",
"            //add xml ns for root svg element, so the image element can be exported to canvas\n",
"            ",'\u0024',"(selection.node().parentNode.parentNode).attr(\"xmlns:xlink\", \"http://www.w3.org/1999/xlink\");\n",
"\n",
"            //save instance variables to local variables because *this* is not referenced to instance in selection.each\n",
"            var _data = this._data, _width = this._width, _height = this._height, _colorPalette = this._colorPalette, _properties = this._properties, _dispatch = this._dispatch;\n",
"            _dispatch.startToInit();\n",
"            selection.each(function() {\n",
"                //prepare canvas with width and height of div container\n",
"                d3.select(this).selectAll('g.vis').remove();\n",
"                var vis = d3.select(this).append('g').attr('class', 'vis').attr('width', _width).attr('height', _height);\n",
"\n",
"                render.call(this, _data, vis, _width, _height, _colorPalette, _properties, _dispatch);\n",
"\n",
"            });\n",
"            _dispatch.initialized({\n",
"                name : \"initialized\"\n",
"            });\n",
"        };\n",
"\n",
"        /*\n",
"         * get/set your color palette if you support color palette\n",
"         */\n",
"        moduleFunc.colorPalette = function(_) {\n",
"            if (!arguments.length) {\n",
"                return this._colorPalette;\n",
"            }\n",
"            this._colorPalette = _;\n",
"            return this;\n",
"        };\n",
"\n",
"        /*flow Definition*/\n",
"        /*<<flow*/\n",
"        var flowRegisterFunc = function(){\n",
"            var flow = sap.viz.extapi.Flow.createFlow({\n",
"                id : '",extn.Id,"',\n",
"                name : '",extn.Name,"',\n",
"                dataModel : 'sap.viz.api.data.CrosstableDataset',\n",
"                type : 'BorderSVGFlow'\n",
"            });\n",
"            var element  = sap.viz.extapi.Flow.createElement({\n",
"                id : 'sap.viz.ext.module.HelloWorldModule',\n",
"                name : 'Hello World Module',\n",
"            });\n",
"            element.implement('sap.viz.elements.common.BaseGraphic', moduleFunc);\n",
"            /*Feeds Definition*/\n",
"            //ds1: City, Year\n",
"            var ds1 = {\n",
"                \"id\": \"sap.viz.ext.module.HelloWorldModule.DS1\",\n",
"                \"name\": \"Entity\",\n",
"                \"type\": \"Dimension\",\n",
"                \"min\": 1,\n",
"                \"max\": 2,\n",
"                \"aaIndex\": 1\n",
"            };\n",
"            _util.mapping.dses.push(\"Entity\");\n",
"            //ms1: Margin, Quantity sold, Sales revenue\n",
"            var ms1 = {\n",
"                \"id\": \"sap.viz.ext.module.HelloWorldModule.MS1\",\n",
"                \"name\": \"Sales Data\",\n",
"                \"type\": \"Measure\",\n",
"                \"min\": 1,\n",
"                \"max\": Infinity,\n",
"                \"mgIndex\": 1\n",
"            };\n",
"            _util.mapping.mses.push(\"Sales Data\");\n",
"            element.addFeed(ds1);\n",
"            element.addFeed(ms1);\n",
"            flow.addElement({\n",
"                'element':element,\n",
"                'propertyCategory' : '",extn.Id,"'\n",
"            });\n",
"            sap.viz.extapi.Flow.registerFlow(flow);\n",
"        };\n",
"        flowRegisterFunc.id = '",extn.Id,"';\n",
"         \n",
"        /*flow>>*/  \n",
"        var flowDefinition = {\n",
"          id:flowRegisterFunc.id,\n",
"          init:flowRegisterFunc  \n",
"        };\n",
"\n",
"        /*<<bundle*/\n",
"        var vizExtImpl = {\n",
"            viz   : [flowDefinition],\n",
"            module: [],\n",
"            feeds : []\n",
"        };\n",
"        var vizExtBundle = sap.bi.framework.declareBundle({\n",
"            \"id\" : \"",extn.Id,"\",\n",
"            \"loadAfter\" : [\"sap.viz.aio\"],\n",
"            \"components\" : [{\n",
"                \"id\" : \"",extn.Id,"\",\n",
"                \"provide\" : \"sap.viz.impls\",\n",
"                \"instance\" : vizExtImpl,\n",
"                \"customProperties\" : {\n",
"                    \"name\" : \"",extn.Name,"\",\n",
"                    \"description\" : \"",extn.Name,"\",\n",
"                    \"icon\" : {\"path\" : \"\"},\n",
"                    \"category\" : [],\n",
"                    \"resources\" : [{\"key\":\"sap.viz.api.env.Template.loadPaths\", \"path\":\"./resources/templates\"}]\n",
"                }\n",
"            }]\n",
"       });\n",
"       // sap.bi.framework.getService is defined in BundleLoader, which is\n",
"       // always available at this timeframe\n",
"       // in standalone mode sap.viz.js will force load and active the\n",
"       // \"sap.viz.aio\" bundle\n",
"       if (sap.bi.framework.getService(\"sap.viz.aio\", \"sap.viz.extapi\")) {\n",
"           // if in standalone mode, sap.viz.loadBundle will be available,\n",
"           // and we load the bundle directly\n",
"           sap.bi.framework.getService(\"sap.viz.aio\", \"sap.viz.extapi\").core.registerBundle(vizExtBundle);\n",
"       } else {\n",
"           // if loaded by extension framework, return the \"sap.viz.impls\"\n",
"           // provider component via define()\n",
"           define(function() {\n",
"               return vizExtBundle;\n",
"           });\n",
"       } \n",
"        /*bundle>>*/ \n",
"\n",
"        //register the chart so it can be created\n",
"    })();\n",
"\n",
"})();\n"
)
    
    if fileotpt.flag==true
        write(file,jsCodeString)
        close(file)
    else
        return true
    end    
end

function createTemplate(path)
    templateCode = string("var sampleTemplate = \n",
"{\n",
"    \"id\": \"sample\",\n",
"    \"name\": \"Sample\",\n",
"    \"properties\": {\n",
"        \"",extn.Id,"\": {\n",
"            \"legend\": {\n",
"                \"title\": {\n",
"                    \"visible\": true,\n",
"                    \"text\": \"Legends\"\n",
"                }\n",
"            }\n",
"        }\n",
"    },\n",
"    \"css\": \".viz-title-label.v-title {fill: #000fff}\"\n",
"};\n",
"sap.viz.extapi.env.Template.register(sampleTemplate);\n"
)
    
    if fileotpt.flag==true
        file = open(path,"w")
        write(file,templateCode)
        close(file)
    else
        true
    end    
    
end    

end # module
