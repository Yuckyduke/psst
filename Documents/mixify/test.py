import app.spotify as spotify

if __name__ == "__main__":
    test = spotify.spotifyHandler("01f4d277eb0a45a9a5fbd08cce6a6afe")
    test.authenticate()
    cheese = test.getCode()
    print(cheese.content)