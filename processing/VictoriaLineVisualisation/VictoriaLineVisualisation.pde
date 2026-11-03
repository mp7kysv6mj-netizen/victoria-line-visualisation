
import java.util.HashSet;
import java.util.ArrayList;

Table observations;

ArrayList<String> stationNames = new ArrayList<String>();
ArrayList<Integer> arrivalTimes = new ArrayList<Integer>();

String selectedTrain = "222";
String selectedDestination = "Walthamstow Central";
String selectedSnapshot = "";

String[] victoriaStations = {
  "Brixton",
  "Stockwell",
  "Vauxhall",
  "Pimlico",
  "Victoria",
  "Green Park",
  "Oxford Circus",
  "Warren Street",
  "Euston",
  "King's Cross St. Pancras",
  "Highbury & Islington",
  "Finsbury Park",
  "Seven Sisters",
  "Tottenham Hale",
  "Blackhorse Road",
  "Walthamstow Central"
};

float trackX = 100;
float startY = 150;
float spacing = 30;

int snapshotTime;

void setup() {

  size(800, 700);
  pixelDensity(1);

  observations = loadTable("victoria_line_observations.csv", "header");

  if (observations == null) {
    println("ERROR: Could not load CSV file.");
    exit();
    return;
  }

  println("Dataset loaded: " + observations.getRowCount());

  // Find the first snapshot for train 222
  for (TableRow row : observations.rows()) {

    if (row.getString("vehicleId").equals(selectedTrain)) {
      selectedSnapshot = row.getString("capturedAt");
      break;
    }
  }

  if (selectedSnapshot.equals("")) {
    println("Train 222 was not found.");
    exit();
    return;
  }

  // Load predictions from the selected snapshot
  for (TableRow row : observations.rows()) {

    if (row.getString("vehicleId").equals(selectedTrain) &&
        row.getString("capturedAt").equals(selectedSnapshot)) {

      stationNames.add(row.getString("stationName"));
      arrivalTimes.add(row.getInt("timeToStation"));
    }
  }

  // Sort predictions by arrival time
  for (int i = 0; i < arrivalTimes.size(); i++) {

    for (int j = i + 1; j < arrivalTimes.size(); j++) {

      if (arrivalTimes.get(j) < arrivalTimes.get(i)) {

        int tempTime = arrivalTimes.get(i);
        arrivalTimes.set(i, arrivalTimes.get(j));
        arrivalTimes.set(j, tempTime);

        String tempStation = stationNames.get(i);
        stationNames.set(i, stationNames.get(j));
        stationNames.set(j, tempStation);
      }
    }
  }

  // Remove duplicate station predictions
  HashSet<String> seenStations = new HashSet<String>();

  ArrayList<String> uniqueNames = new ArrayList<String>();
  ArrayList<Integer> uniqueTimes = new ArrayList<Integer>();

  for (int i = 0; i < stationNames.size(); i++) {

    if (!seenStations.contains(stationNames.get(i))) {

      seenStations.add(stationNames.get(i));

      uniqueNames.add(stationNames.get(i));
      uniqueTimes.add(arrivalTimes.get(i));
    }
  }

  stationNames = uniqueNames;
  arrivalTimes = uniqueTimes;

  // Sort predictions geographically northbound
  for (int i = 0; i < stationNames.size(); i++) {

    for (int j = i + 1; j < stationNames.size(); j++) {

      int first = getStationIndex(stationNames.get(i));
      int second = getStationIndex(stationNames.get(j));

      if (first >= 0 && second >= 0 && second < first) {

        String tempStation = stationNames.get(i);
        stationNames.set(i, stationNames.get(j));
        stationNames.set(j, tempStation);

        int tempTime = arrivalTimes.get(i);
        arrivalTimes.set(i, arrivalTimes.get(j));
        arrivalTimes.set(j, tempTime);
      }
    }
  }

  snapshotTime = millis();

  println("Train " + selectedTrain + " loaded.");
  println("Predicted stops: " + stationNames.size());
}

int getStationIndex(String station) {

  for (int i = 0; i < victoriaStations.length; i++) {

    if (station.equals(victoriaStations[i] + " Underground Station")) {
      return i;
    }
  }

  return -1;
}

void draw() {

  background(24, 29, 38);

  float elapsedSeconds = (millis() - snapshotTime) / 1000.0;

  // Header
  fill(255);
  textSize(27);
  text("VICTORIA LINE", 30, 38);

  fill(170, 180, 195);
  textSize(12);
  text("FULL NORTHBOUND ROUTE VISUALISATION", 32, 60);

  // Information panel
  fill(39, 47, 60);
  noStroke();
  rect(30, 75, 740, 65, 12);

  fill(255);
  textSize(15);
  text("TRAIN ID: " + selectedTrain, 50, 102);

  fill(230, 190, 55);
  text("NORTHBOUND", 50, 125);

  fill(255);
  text("BRIXTON TO WALTHAMSTOW CENTRAL", 330, 102);

  fill(170, 180, 195);
  text("Predicted stops: " + stationNames.size(), 330, 125);

  // Draw the complete Victoria line
  stroke(0, 160, 220);
  strokeWeight(6);

  line(
    trackX,
    startY,
    trackX,
    startY + (victoriaStations.length - 1) * spacing
  );

  // Draw all 16 stations
  for (int i = 0; i < victoriaStations.length; i++) {

    float stationY = startY + i * spacing;

    fill(24, 29, 38);
    stroke(0, 160, 220);
    strokeWeight(3);

    ellipse(trackX, stationY, 13, 13);

    fill(255);
    textSize(12);
    text(victoriaStations[i], 130, stationY + 4);
  }

  // Find the next predicted station
  int nextStation = 0;

  while (nextStation < arrivalTimes.size() &&
         arrivalTimes.get(nextStation) <= elapsedSeconds) {

    nextStation++;
  }

  // Calculate the train's position
  if (stationNames.size() > 0) {

    float trainY;

    if (nextStation == 0) {

      int index = getStationIndex(stationNames.get(0));
      trainY = startY + index * spacing;

    } else if (nextStation >= stationNames.size()) {

      int index = getStationIndex(
        stationNames.get(stationNames.size() - 1)
      );

      trainY = startY + index * spacing;

    } else {

      int previousIndex = getStationIndex(
        stationNames.get(nextStation - 1)
      );

      int nextIndex = getStationIndex(
        stationNames.get(nextStation)
      );

      float previousTime = arrivalTimes.get(nextStation - 1);
      float nextTime = arrivalTimes.get(nextStation);

      float duration = max(1, nextTime - previousTime);

      float progress =
        (elapsedSeconds - previousTime) / duration;

      progress = constrain(progress, 0, 1);

      float previousY = startY + previousIndex * spacing;
      float nextY = startY + nextIndex * spacing;

      trainY = lerp(previousY, nextY, progress);
    }

    // Draw the train marker
    fill(255, 190, 50);
    noStroke();
    ellipse(trackX, trainY, 22, 22);

    // Display countdown
    if (nextStation < stationNames.size()) {

      int remaining = max(
        0,
        ceil(arrivalTimes.get(nextStation) - elapsedSeconds)
      );

      fill(255, 190, 50);
      textSize(13);
      text(
        "NEXT STOP: " + stationNames.get(nextStation)
          .replace(" Underground Station", ""),
        330,
        180
      );

      fill(255);
      text(
        "ESTIMATED ARRIVAL: " + formatTime(remaining),
        330,
        205
      );

    } else {

      fill(255, 190, 50);
      textSize(13);
      text("END OF AVAILABLE PREDICTIONS", 330, 180);
    }
  }

  // Footer
  fill(130, 145, 165);
  textSize(11);
  text("Source: Transport for London arrival predictions", 30, 650);
  text("Full route shown; train position uses recorded predictions", 30, 670);
}

String formatTime(int seconds) {

  int minutes = seconds / 60;
  int remainingSeconds = seconds % 60;

  return nf(minutes, 2) + ":" + nf(remainingSeconds, 2);
}
