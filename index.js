import axios from "axios";
import fs from "node:fs";
import "dotenv/config";
import { stringify } from "csv-stringify";

const clientId = process.env.CLIENT_ID;
const clientSecret = process.env.CLIENT_SECRET;

const authorizationHeader = `Basic ${Buffer.from(
  `${clientId}:${clientSecret}`
).toString("base64")}`;

const authData = {
  grant_type: "client_credentials",
};

const fileName = `${new Date()
  .toString()
  .replace(/:/g, "-")
  .replace(/\s+/g, "-")}_spotify.csv`;

const columns = [
  "song",
  "artist",
  "duration",
  "release_date",
  "popularity",
  "album",
  "album_type",
];

const writableStream = fs.createWriteStream(fileName);

const getAccessToken = async () => {
  try {
    const response = await axios.post(
      "https://accounts.spotify.com/api/token",
      new URLSearchParams(authData).toString(),
      {
        headers: {
          Authorization: authorizationHeader,
          "Content-Type": "application/x-www-form-urlencoded",
        },
      }
    );
    return response.data.access_token;
  } catch (error) {
    throw new Error("Failed to obtain access token");
  }
};

const fetchPlaylistData = async () => {
  try {
    const accessToken = await getAccessToken();

    const response = await axios.get(
      "https://api.spotify.com/v1/playlists/37i9dQZF1DXcBWIGoYBM5M",
      {
        headers: {
          Authorization: `Bearer ${accessToken}`,
        },
      }
    );

    const stringified = stringify({
      header: true,
      columns: columns,
      delimiter: " | ",
    });
    response.data.tracks.items.map((item) => {
      let row = {
        song: item?.track?.name,
        artist: item?.track?.artists[0]?.name,
        duration: `${(item?.track?.duration_ms / 60000).toFixed(2)} minutes`,
        release_date: item?.track?.album?.release_date,
        popularity: `${item?.track?.popularity} out of 100`,
        album: item?.track?.album?.name,
        album_type: item?.track?.album?.album_type,
      };
      stringified.write(row);
    });
    stringified.pipe(writableStream);
  } catch (error) {
    console.error("Error:", error);
  }
};

await fetchPlaylistData();
