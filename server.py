#!/usr/bin/env python3

import os.path
import simplejson as json

from flask import Flask
from flask import render_template
from flask import send_from_directory


STATIC_DIR = os.path.dirname(os.path.abspath(__file__))


app = Flask(__name__, template_folder='.', static_url_path=STATIC_DIR)
app.secret_key = ''


@app.route('/')
def main():
    return render_template('index.html')


@app.route('/eval/')
def eval():
    return json.dumps([88.5])


@app.route('/<path:path>')
def serve_file(path):
    return send_from_directory('.', path)


if __name__ == '__main__':
    app.run(debug=True, port=7777)
