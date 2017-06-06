#!/usr/bin/env python3

import os.path
import simplejson as json

from flask import Flask
from flask import jsonify
from flask import render_template
from flask import request
from flask import send_from_directory


STATIC_DIR = os.path.dirname(os.path.abspath(__file__))


app = Flask(__name__, template_folder='.', static_url_path=STATIC_DIR)
app.secret_key = ''


@app.route('/')
def main():
    return render_template('index.html')


@app.route('/eval/', methods=['POST'])
def eval():
    data = request.json
    text = data['text']
    return jsonify(json.dumps([len(text)]))


@app.route('/next/', methods=['POST'])
def next():
    data = request.json
    text = data['text']
    return jsonify(json.dumps(text.split()))


@app.route('/<path:path>')
def serve_file(path):
    return send_from_directory('.', path)


if __name__ == '__main__':
    app.run(debug=True, port=7777)
