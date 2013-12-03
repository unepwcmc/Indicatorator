fs = require('fs')
Q = require('q')
_ = require('underscore')

GDocGetter = require('../getters/gdoc')
GDocFormatter = require('../formatters/gdoc')
StandardIndicatorator = require('../indicatorators/standard_indicatorator')

module.exports = class Indicator
  constructor: (attributes) ->
    _.extend(@, attributes)

  query: ->
    new GDocGetter(@).then( (data) ->
      formattedData = GDocFormatter(data)
      StandardIndicatorator.applyRanges(formattedData, [
        {"minValue": 1, "message": "Excellent"},
        {"minValue": 0.5, "message": "Moderate"},
        {"minValue": 0.1, "message": "Poor"},
        {"minValue": 0, "message": "Not Started"}
      ])
    )

  @find: (id) ->
    deferred = Q.defer()

    Q.nsend(
      fs, 'readFile', './definitions/indicators.json'
    ).then( (definitionsJSON) ->

      definitions = JSON.parse(definitionsJSON)
      indicator = new Indicator(
        _.findWhere(definitions, id: id)
      )

      deferred.resolve(indicator)
    ).fail(
      deferred.reject
    )

    return deferred.promise
