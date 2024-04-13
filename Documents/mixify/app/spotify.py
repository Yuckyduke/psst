import requests
import random
from flask import redirect, request, jsonify
from urllib.parse import urlencode
import base64

class spotifyHandler:

    def __init__(self, clientID: str) -> None:
        self.clientID = clientID
        self._scope = "user-read-private user-read-email streaming playlist-read-private playlist-read-collaborative user-read-currently-playing user-modify-playback-state"
        self.redirect_uri = "http://127.0.0.1:5000/callback"
        self.spot_url = "https://accounts.spotify.com/"
        self.params = {"client_id": self.clientID, "response_type": "code", "redirect_uri" :self.redirect_uri, "scope": self._scope}
        self.secret = "bd5fb29c425c4d108f34f44a78bebb52"
        self.spotifyTokenURL = 'https://accounts.spotify.com/api/token'

    def getCode(self) -> None:
        self.code = requests.get(url = self.spot_url + 'login',params= {"client_id":self.clientID, "response_type":"code", "redirect_uri": self.redirect_uri, "scope": self._scope}) 
        return self.code
 
    def authenticate(self) -> None:
        authorizeUrl = self.spot_url + "authorize"
        return redirect(f'{authorizeUrl}?{urlencode(self.params)}')
    
    def get_access_token(self, auth_code):
    # Exchange authorization code for access token
        headers = {
            'Authorization': f'Basic {base64.b64encode(f"{self.clientID}:{self.secret}".encode()).decode()}',
        }
        data = {
            'grant_type': 'authorization_code',
            'code': auth_code,
            'redirect_uri': self.redirect_uri,
        }
        response = requests.post(self.spotifyTokenURL, headers=headers, data=data)
        return response.json()

    def playlists(self, access_token):
    # return playlist names and ids
        response = requests.get("https://api.spotify.com/v1/me/playlists", headers= {"Authorization": "Bearer " + access_token})
        items = response.json()['items']
        playlistDict = {}
        for item in items:
            playlistDict[item['name']] = item['id']
        return playlistDict
    
    def playPlaylist(self, playlistID, access_token):
        #play a playlist
        response = requests.put("https://api.spotify.com/v1/me/player/play", headers= {"Authorization": "Bearer " + access_token}, data={"context_uri": f"spotify:playlist:{playlistID}"})
        return response
    
    def getPlaylistSongs(self, access_token, playlist_id):
        # return the songs of a playlist
        response = requests.get(f"https://api.spotify.com/v1/playlists/{playlist_id}", headers ={"Authorization": "Bearer " + access_token}).json()
        returnArray = []
        # while response["tracks"]["next"]:
        # for item in response["tracks"]["items"]:
        #     currentTrack = {"name": item["track"]["name"], "id": item["track"]["uri"], "artists": item["track"]["artists"][0]["name"], "duration": item["track"]["duration_ms"]}
        #     # self.add_song_to_queue(item["track"]["uri"], access_token)
        #     returnArray.append(currentTrack)
        # self.playPlaylist(playlistID=playlist_id, access_token=access_token)
        # return jsonify({"tracks": returnArray})
        responseItems = response["tracks"]["items"]
        for i in range(len(response["tracks"]["items"])):
            currentTrack = {"row": i, "name": responseItems[i]["track"]["name"], "id": responseItems[i]["track"]["uri"], "artists": responseItems[i]["track"]["artists"][0]["name"], "duration": responseItems[i]["track"]["duration_ms"]}
            returnArray.append(currentTrack)
        return jsonify({"tracks": returnArray})
    

    def add_song_to_queue(self, song_uri, access_token):
    # Add the song to the queue
        add_to_queue_url = f'https://api.spotify.com/v1/me/player/queue?uri={song_uri}'
        headers = {'Authorization': f'Bearer {access_token}'}
        response = requests.post(url=add_to_queue_url, headers=headers)

        if response.status_code == 202:
            print("Song added to the queue successfully.")
        else:
            print(f"Failed to add song to the queue. Status code: {response.status_code}") 

    def getQueue(self, access_token):
        #return the queue
        response = requests.get("https://api.spotify.com/v1/me/player/queue", headers ={"Authorization": "Bearer " + access_token}).json()
        return response

    def getSongDuration(self, songURI, access_token):
        songID = self.uriToID(songURI)
        response = requests.get(f"https://api.spotify.com/v1/tracks/{songID}", headers ={"Authorization": "Bearer " + access_token}).json()
        return str(response["duration_ms"])

    def uriToID(self, songURI):
        test = songURI[songURI.find(":") + 1:]
        test = test[test.find(":") + 1:]
        return test

    def clearQueue(self, access_token):
        #clear the current queue
        while self.getQueue(access_token):
            requests.post(url = "https://api.spotify.com/v1/me/player/next", headers = {"Authorization": "Bearer " + access_token})


     
