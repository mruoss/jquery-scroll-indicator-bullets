gulp				= require('gulp')
coffee			= require('gulp-coffee')
concat      = require('gulp-concat')
autoprefixer = require('autoprefixer')
filter			= require('gulp-filter')
uglify			= require('gulp-uglify')
del          = require('del')
runSequence  = require('run-sequence') # to be replaced with gulp.runSeries (next gulp version) see  https://github.com/gulpjs/gulp/issues/347
postcss     = require('gulp-postcss')
plumber     = require('gulp-plumber')
sass        = require('gulp-sass')
gutil       = require('gulp-util')


src =
	sass: ["sass/jquery.scrollindicatorbullets.sass"],
	coffee: ["src/jquery.scrollindicatorbullets.coffee"]

target = "./dist"

plumber_options =
	errorHandler: (err) ->
		gutil.log err
		gutil.log err.toString()
		gutil.beep()

		@emit('end')

gulp.task 'stylesheets', ->
	sassOptions =
		indentedSyntax: true
		# outputStyle: 'compressed'
		# includePaths: neat.includePaths
		# errLogToCSS: true

	supported_browsers = '> 1%, last 3 versions, Firefox ESR'

	postProcess = postcss([
		autoprefixer({ browsers: supported_browsers })
	])

	sassStream = gulp.src src.sass
		.pipe plumber(plumber_options)

		.pipe sass(sassOptions)
		.pipe postProcess
		.pipe gulp.dest(target)

	return sassStream

gulp.task 'scripts', ->
	stream = gulp.src(src.coffee)
		.pipe plumber(plumber_options)
    .pipe coffee()
		.pipe concat('jquery.scrollindicatorbullets.js')
		.pipe gulp.dest(target)
		.pipe uglify()
		.pipe concat('jquery.scrollindicatorbullets.min.js')
		.pipe gulp.dest(target)

	return stream

gulp.task 'clean', (callback) ->
	del target, callback

gulp.task 'build', (callback) ->
	runSequence 'clean', [ 'stylesheets', 'scripts'], callback

gulp.task 'serve', [ 'build' ], ->
	gulp.watch src.sass, [ 'stylesheets' ]
	gulp.watch src.coffee, [ 'scripts' ]

gulp.task 'default', (callback) ->
	runSequence 'serve', callback
