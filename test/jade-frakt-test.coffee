fs = require 'fs'
async = require 'async'
curry = require('naan').curry
assert = require 'assert'
global.jade = require 'jade'
tmw = require '../'

describe 'Templates Middleware', ->
  dir = './test/tw_test_area'
  graceperiod = 0

  beforeEach ->
    fs.mkdirSync dir
    fs.writeFileSync "#{dir}/f1", "data-1"
    fs.writeFileSync "#{dir}/f2", "data-2"

  rmdir = (ok) ->
    require('child_process').spawn('rm', ['-rf', dir]).on('exit', -> ok())

  afterEach rmdir
  after rmdir

  responseMock = (callback) ->
    send: (code, err) -> callback err
    local: (name, val) -> callback null, val, 'local'
    expose: (fn, name) -> callback null, fn, 'expose'

  it 'should read initial templates', (done) ->
    middleware = tmw dir
    response = responseMock (err, vals) ->
      assert.ok not err, err
      assert.equal vals['f1'], 'data-1'
      assert.equal vals['f2'], 'data-2'
      done()
    middleware null, response, ->

  it 'should update values when the files change', (done) ->
    middleware = tmw dir
    response = responseMock (err, vals) ->
      assert.ok not err, err
      assert.equal vals['f1'], 'data-1'
      assert.equal vals['f2'], 'data-4'
      assert.equal vals['f3'], 'data-3'
      done()
    fs.writeFileSync "#{dir}/f2", "data-4"
    fs.writeFileSync "#{dir}/f3", "data-3"
    check = ->
      middleware null, response, ->
    setTimeout check, graceperiod
    
  it 'should pick up new files when they appear', (done) ->
    middleware = tmw dir
    response = responseMock (err, vals) ->
      assert.ok not err, err
      assert.equal vals['f1'], 'data-1'
      assert.equal vals['f2'], 'data-2'
      assert.equal vals['f3'], 'data-3'
      done()
    fs.writeFileSync "#{dir}/f3", "data-3"
    check = ->
      middleware null, response, ->
    setTimeout check, graceperiod
    
  it 'should update values when the files change (with cache)', (done) ->
    middleware = tmw dir, cache: true
    response = responseMock (err, vals) ->
      assert.ok not err, err
      assert.equal vals['f1'], 'data-1'
      assert.equal vals['f2'], 'data-4'
      assert.equal vals['f3'], 'data-3'
      done()
    fs.writeFileSync "#{dir}/f2", "data-4"
    fs.writeFileSync "#{dir}/f3", "data-3"
    check = ->
      middleware null, response, ->
    setTimeout check, graceperiod
    
  it 'should pick up new files when they appear (with cache)', (done) ->
    middleware = tmw dir, cache: true
    response = responseMock (err, vals) ->
      assert.ok not err, err
      assert.equal vals['f1'], 'data-1'
      assert.equal vals['f2'], 'data-2'
      assert.equal vals['f3'], 'data-3'
      done()
    fs.writeFileSync "#{dir}/f3", "data-3"
    check = ->
      middleware null, response, ->
    setTimeout check, graceperiod

  it 'should ignore `index.jade`', (done) ->
    middleware = tmw dir
    response = responseMock (err, vals) ->
      assert.ok not err, err
      assert.equal vals['f1'], 'data-1'
      assert.equal vals['f2'], 'data-2'
      assert.ok not vals['index.jade']
      assert.ok not vals['index']
      done()
    fs.writeFileSync "#{dir}/index.jade", "data-3"
    check = ->
      middleware null, response, ->
    setTimeout check, graceperiod

  it 'should ignore directories', (done) ->
    middleware = tmw dir
    response = responseMock (err, vals) ->
      assert.ok not err, err
      assert.equal vals['f1'], 'data-1'
      assert.equal vals['f2'], 'data-2'
      assert.ok not vals['a_dir']
      done()
    fs.mkdirSync "#{dir}/a_dir"
    check = ->
      middleware null, response, ->
    setTimeout check, graceperiod
    
  it 'should truncate jade file exts', (done) ->
    middleware = tmw dir
    response = responseMock (err, vals) ->
      assert.ok not err, err
      assert.equal vals['f1'], 'data-1'
      assert.equal vals['f2'], 'data-2'
      assert.equal vals['cucumberpickle'], 'data-3'
      done()
    fs.writeFileSync "#{dir}/cucumberpickle.jade", "data-3"
    check = ->
      middleware null, response, ->
    setTimeout check, graceperiod

  it 'should expose pre-cooked JS templates if specified', (done) ->
    middleware = tmw dir, compile: true
    jadeStr = '''
      - var title = 'yay'
      h1.title #{title} #{t}
      p Just an example
    '''
    response = responseMock (err, vals) ->
      assert.ok not err, err
      cjadefn = jade.compile jadeStr, compileDebug: false, compileClient: true

      assert.equal vals['cucumberpickle'].toString(), cjadefn.toString()

      done()
    fs.writeFileSync "#{dir}/cucumberpickle.jade", jadeStr
    check = ->
      middleware null, response, ->
    setTimeout check, graceperiod

  it 'should attempt to expose pre-cooked JS tmpls when expose=true', (done) ->
    middleware = tmw dir, compile: true, expose: true
    jadeStr = '''
      - var title = 'yay'
      h1.title #{title} #{t}
      p Just an example
    '''
    response = responseMock (err, vals, method) ->
      assert.ok not err, err
      assert.equal method, 'expose'

      done()
    fs.writeFileSync "#{dir}/cucumberpickle.jade", jadeStr
    check = ->
      middleware null, response, ->
    setTimeout check, graceperiod
