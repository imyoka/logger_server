gulp = require 'gulp'
bower= require 'gulp-bower'
connect = require 'gulp-connect'
jade = require 'gulp-jade'
browserify = require 'gulp-browserify'
Browserify = require 'browserify'
coffeeify = require 'coffeeify'
babelify = require 'babelify'
watchify = require 'watchify'
cjsxify = require 'coffee-reactify'
source = require 'vinyl-source-stream'
stylus = require 'gulp-stylus'
rename = require 'gulp-rename'
clean = require 'gulp-clean'
plumber = require 'gulp-plumber'
notify = require 'gulp-notify'
mkdirp= require 'mkdirp'
nib = require 'nib'
concat = require 'gulp-concat'
spritesmith = require 'gulp.spritesmith'



paths=
    TestPath: './test'
    jade: 'views/*.jade'
    stylus: 'views/*.styl'
    browserify: 'views/main.coffee'
    bundle: 'views/headH5/*.js'
    sprite: 'views/*.jpg'

mkdirp.sync paths.TestPath

einTask= ['connect', 'watch']

gulp.task 'watch', ->
    gulp.watch [paths.jade, paths.stylus, paths.browserify, paths.sprite], ['jade', 'stylus', 'browserify', 'sprite']

gulp.task 'connect', ->
    connect.server
        root: paths.TestPath
        livereload: true
        port: 3000
        host: 'localhost'

# Jade
gulp.task 'jade', ->
    options =
        pretty: true
        locals:
            path: '.'
            suppeName: []
            suppeName: ['紫菜蛋花汤', '菠菜蛋花汤', '小白菜蛋花汤', '裙带蛋花汤']
            suppePrice: ['1.5', '1.4', '1.3', '1.2']
            suppeCount: ['1', '2', '3', '4']
            priceTotal: '1'
    gulp.src(paths.jade)
    .pipe(plumber(errorHandler: notify.onError("Error: <%= error.message %>")))
    .pipe(jade(options))
    .pipe(gulp.dest(paths.TestPath))
    .pipe(connect.reload())

# Stylus
gulp.task 'stylus', ->
    gulp.src(paths.stylus)
        .pipe(plumber(errorHandler: notify.onError("Error: <%= error.message %>")))
        .pipe(stylus({ use: nib() }))
        .pipe(gulp.dest(paths.TestPath+ '/css'))
        .pipe(connect.reload())

# Browserify + Coffeeify
gulp.task 'browserify', ->
    options =
        entries: paths.browserify
        extensions: ['.coffee', '.cjsx']
        debug: true
        cache: {}
        packageCache: {}
        plugin: ['watchify']
    Browserify(options)
        .transform(cjsxify)
        # .transform('babelify', {presets: ['es2015', 'react']})
        .bundle()
        .pipe(source('main.js'))
        .pipe(gulp.dest(paths.TestPath+ '/js'))
        .pipe(connect.reload())

gulp.task 'bundle', ->
    gulp.src(paths.bundle)
    .pipe(concat("bundle.js"))
    .pipe(gulp.dest(paths.TestPath+ '/js'))

gulp.task 'sprite', ->
    options=
        imgName: 'sprite.png'
        cssName: 'sprite.styl'
        cssFormat: 'stylus'
    gulp.src(paths.sprite)
    .pipe(spritesmith(options))
    .pipe(gulp.dest(paths.TestPath+ '/sprite'))

# bower
# gulp.task 'bower', -> bower()

einTask.push 'jade', 'stylus', 'browserify', 'bundle', 'sprite'

gulp.task 'default', einTask