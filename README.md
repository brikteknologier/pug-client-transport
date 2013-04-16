# jade-frakt

Some express middleware for sending a bunch of
[jade](https://github.com/visionmedia/jade) templates to the client.

### Example

```javascript
var frakt = require('jade-frakt');

var app = express();
app.use(frakt(__dirname + '/clientTemplates'));

// This will yield any jade templates in /clientTemplates as locals in any
// request made. 
```

So if the contents of `./clientTemplates/` was:
```
template-1.jade
template-2.jade
```

You would gain two locals in your express response - `'template-1'` and
`'template-2'` - which are your jade templates as strings.

### frakt(dir, options)

* `dir` - the directory to read templates from
* `options` - optional - custom options

#### options

* `compile` - **default: `false`** - whether or not to precompile your jade 
  templates. the upside of this is that you can use jade features like 
  inheritance on the client side, and all of the template compilation is done 
  first on the server.
* `expose` - **default: `false`** - if set to true, the templates will be 
  exposed using [express-expose](https://github.com/visionmedia/express-expose)
  (express expose also sets them as locals)

### License

MIT
