from flask import Flask, redirect
import os
from urllib.parse import urlencode

app = Flask(__name__)
app.secret_key = os.urandom(24)

# Spotify API credentials
CLIENT_ID = "01f4d277eb0a45a9a5fbd08cce6a6afe"
CLIENT_SECRET = "bd5fb29c425c4d108f34f44a78bebb52"
REDIRECT_URI = 'http://localhost/callback'

# Spotify API endpoints
SPOTIFY_AUTH_URL = 'https://accounts.spotify.com/authorize'
SPOTIFY_TOKEN_URL = 'https://accounts.spotify.com/api/token'


@app.route('/')
def index():
    # Redirect the user to Spotify's authorization page
    params = {
        'client_id': CLIENT_ID,
        'response_type': 'code',
        'redirect_uri': REDIRECT_URI,
        'scope': 'user-read-private user-read-email',  # Add additional scopes as needed
    }
    auth_url = f'{SPOTIFY_AUTH_URL}?{urlencode(params)}'
    return redirect(auth_url)


# @app.route('/callback')
# def callback():
#     # Handle the callback from Spotify
#     auth_code = request.args.get('code')

#     # Exchange authorization code for access token
#     token_data = get_access_token(auth_code)
#     access_token = token_data.get('access_token')

#     # Store the access token in the session (you may want to store it securely in a production environment)
#     session['access_token'] = access_token

#     # Redirect to a page where you can use the access token
#     return redirect(url_for('profile'))


# @app.route('/profile')
# def profile():
#     # Get user profile using the stored access token
#     access_token = session.get('access_token')
#     if not access_token:
#         return redirect(url_for('index'))

#     headers = {
#         'Authorization': f'Bearer {access_token}',
#     }
#     response = requests.get('https://api.spotify.com/v1/me', headers=headers)

#     if response.status_code == 200:
#         user_data = response.json()
#         return f'Logged in as {user_data["display_name"]} ({user_data["id"]})'
#     else:
#         return f'Error retrieving user profile: {response.text}'


# def get_access_token(auth_code):
#     # Exchange authorization code for access token
#     headers = {
#         'Authorization': f'Basic {base64.b64encode(f"{CLIENT_ID}:{CLIENT_SECRET}".encode()).decode()}',
#     }
#     data = {
#         'grant_type': 'authorization_code',
#         'code': auth_code,
#         'redirect_uri': REDIRECT_URI,
#     }
#     response = requests.post(SPOTIFY_TOKEN_URL, headers=headers, data=data)
#     return response.json()


if __name__ == '__main__':
    app.run(debug=True)
