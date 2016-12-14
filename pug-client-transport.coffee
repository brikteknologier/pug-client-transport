fs = require 'fs'
async = require 'async'
curry = require('naan').curry
_ = require 'underscore'
Emitter = require('events').EventEmitter
pug = require 'pug'
path = require 'path'

# This is a little utility that is intended to supply a set of templates to a
# view, through express middleware. It reads every file in the specified
# directory and sets a view local `templates` as a hash of the filenames and
# their data.
# 
# Opts:
# `compile`:      if this is truthy, the templates are compiled first to js fns.
#                 defaults to false.
# `cache`:        if this is truthy, file contents are cached and only updated
#                 when they change. defaults to true when NODE_ENV = production
# `expose`:       exposes the templates to the client via express-expose.
#                 default is false.
module.exports = (directory, opts) ->
  readQueue = async.queue ((task, callback) -> task callback), 1

  templates = null

  opts ?= {}
  opts.compile ?= false
  opts.cache ?= true
  opts.expose ?= false

  readTemplates = (callback) ->
    fs.readdir directory, (err, files) ->
      return callback err if err
      files = _.reject files, (file) -> file is 'index.pug'

      tolerantReadFile = (filename, callback) ->
        fs.readFile filename, (err, data) ->
          if err
            callback (if err.code is 'EISDIR' then null else err), false
          else
            callback null, data

      tasks = (curry tolerantReadFile, "#{directory}/#{file}" for file in files)
      async.parallel tasks, (err, contents) ->
        return callback err if err
        templatesData = {}
        contents.forEach (data, i) ->
          return if not data
          data = data.toString()
          if opts.compile
            data = pug.compileClient(data, {
              compileDebug: false,
              inlineRuntimeFunctions: false,
              filename: path.resolve(directory, files[i])
            })
          filename = files[i].replace(/\.pug/i, "")
          templatesData[filename] = data
        callback null, templatesData

  updateTemplates = (callback) ->
    readTemplates (err, templatesData) ->
      return callback err if err
      templates = templatesData
      callback null, templates

  fetchTemplates = if not opts.cache then readTemplates else (callback) ->
    return callback null, templates if templates
    updateTemplates callback
    
  if opts.cache
    fs.watch directory, ->
      readQueue.push updateTemplates, ->

  (req, res, next) ->
    fetchTemplates (err, templates) ->
      return res.send err, 500 if err
      if opts.expose
        res.expose templates, 'templates'
      else
        res.locals.templates = templates
      next()
