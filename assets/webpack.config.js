const path = require('path');
const glob = require('glob');
const webpack = require('webpack');
const MiniCssExtractPlugin = require('mini-css-extract-plugin');
const UglifyJsPlugin = require('uglifyjs-webpack-plugin');
const OptimizeCSSAssetsPlugin = require('optimize-css-assets-webpack-plugin');
const CopyWebpackPlugin = require('copy-webpack-plugin');

module.exports = (env, options) => ({
  optimization: {
    minimizer: [
      new UglifyJsPlugin({ cache: true, parallel: true, sourceMap: false }),
      new OptimizeCSSAssetsPlugin({})
    ]
  },
  entry: ['./js/app.js', './css/app.css'],
  output: {
    filename: 'js/app.js',
    path: path.resolve(__dirname, '../priv/static')
  },
  module: {
    rules: [
      {
        test: /\.js$/,
        exclude: /node_modules/,
        use: ['babel-loader']
      },
      {
          test: /\.css$/,
          use:  [  MiniCssExtractPlugin.loader, 'css-loader']
      },
      {
        test: /\.(woff|woff2|eot|ttf|svg)$/,
        loader: "file-loader",
        options: {outputPath: "fonts", publicPath: "/fonts"}
      }
    ]
  },
  plugins: [
    new MiniCssExtractPlugin({ filename: 'css/app.css' }),
    new MiniCssExtractPlugin({ filename: 'css/resume.css' }),
    new CopyWebpackPlugin([{ from: 'static/', to: '.' }]),
    new webpack.ProvidePlugin({
      $: "jquery",
      jQuery: "jquery",
      "window.jQuery": "jquery"
    })
  ]
});
