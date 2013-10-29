request = require('request')
_ = require('underscore')
fs = require('fs')
{parseString} = require('xml2js')


indicatorDefinitions = JSON.parse(fs.readFileSync('./ede_indicator_definitions.json', 'UTF8'))

API_URL = "localhost:3003"

makeGetUrl = (dataset) ->
  "http://#{API_URL}/#{dataset}/"

validateindicatordata = (data) ->
  unless data.rows?
    throw new Error("EDE data should ahve XX feature or something - TODO!")

calculateIndicatorText = (indicatorCode, value) ->
  value = parseFloat(value)
  try
    ranges = indicatorDefinitions[indicatorCode].ranges
  catch e
    console.error e.stack
    throw new Error("I don't know this indicator, please check the request parameters")

  for range in ranges
    return range.message if value > range.minValue

  return "Error: Value #{value} outside expected range"

indicatorate = (indicatorCode, data) ->
  console.log indicatorCode
  deliciousCore = data['SOAP-ENV:Envelope']['SOAP-ENV:Body'][0]['ns1:DataSearchResponse'][0]['Return'][0]['DataSets'][0]['item'][0]['ValueSets'][0]['item']
  data = _.map deliciousCore, (i) ->
    year: i['Year'][0]['_']
    value: i['Value'][0]['_']
    text: calculateIndicatorText(indicatorCode, i['Value'][0]['_'])

  data = data.filter (i) ->
    if i.year != "name"
      return i

  return data

  text = calculateIndicatorText(indicatorCode, value)

  return {
    data: [
      value: value
      periodStart: year
      text: text
    ]
  }

module.exports = (req, res) ->
  {dataset} = req.params
  indicatorCode = "#{dataset}"
  url = makeGetUrl(dataset)

  xml = fs.readFileSync('ede_sample.xml','utf8') # Replace with request to actual feed

  parseString(xml,(err,result)-> 
    if err? 
      console.error err
      throw err
      res.send(500, "Couldn't parse XML for #{url}")
    try
      indicatorData = indicatorate(indicatorCode, result)
      res.send(200, JSON.stringify(indicatorData))
    catch e
      console.error e.stack
      res.send(500, e.toString())
  )
  return
  request.get(
    url: url
  , (err, response) ->
    if err?
      console.error err
      throw err
      res.send(500, "Couldn't query data for #{url}")

    try
      indicatorData = indicatorate(indicatorCode, response.body)
      res.send(200, JSON.stringify(indicatorData))
    catch e
      console.error e.stack
      res.send(500, e.toString())
  )


