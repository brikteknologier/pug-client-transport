# pug-client-transport

Some express middleware for sending a bunch of
[pug](https://github.com/visionmedia/pug) templates to the client.

### Example

```javascript
var clientTemplates = require('pug-client-transport');

var app = express();
app.use(clientTemplates(__dirname + '/clientTemplates'));

// This will yield any pug templates in /clientTemplates as locals under the
// `res.locals.templates` object in any request made. 
```

So if the contents of `./clientTemplates/` was:
```
template-1.pug
template-2.pug
```

You would gain an object with two properties - `'template-1'` and
`'template-2'` in your `res.locals` - which are your pug templates as strings.

### pugClientTransport(dir, options)

* `dir` - the directory to read templates from
* `options` - optional - custom options

#### options

* `compile` - **default: `false`** - whether or not to precompile your pug 
  templates. the upside of this is that you can use pug features like 
  inheritance on the client side, and all of the template compilation is done 
  first on the server.
* `expose` - **default: `false`** - if set to true, the templates will be 
  exposed using [express-expose](https://github.com/visionmedia/express-expose)
  (express expose also sets them as locals)

### License

MIT
