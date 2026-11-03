import java.util.ArrayList;

Table observations;

String selectedTrain = "222";

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

ArrayList<String> stationNames = new ArrayList<String>();
ArrayList<Float> arrivalTimes = new ArrayList<Float>();

float trackX = 100;
float startY = 150;
float spacing = 30;

int sketchStartTime;

void setup() {
  size(800, 700);

  observations = loadTable("victoria_line_observations.csv", "header");

  if (observations == null) {
    println("Could not load CSV file.");
    exit();
  }

  String selectedSnapshot = "";

  for (TableRow row : observations.rows()) {
    if (row.getString("vehicleId").equals(selectedTrain)) {
      selectedSnapshot = row.getString("capturedAt");
      break;
    }
  }

  if (selectedSnapshot.equals("")) {
    println("Selected train was not found.");
    exit();
  }

  for (TableRow row : observations.rows()) {
    String vehicleId = row.getString("vehicleId");
    String capturedAt = row.getString("capturedAt");

    if (vehicleId.equals(selectedTrain) &&
        capturedAt.equals(selectedSnapshot)) {

      String station = row.getString("stationName");
      float time = row.getFloat("timeToStation");

      if (!stationNames.contains(station)) {
        stationNames.add(station);
        arrivalTimes.add(time);
      }
    }
  }

  // Sort predictions by arrival time
  for (int i = 0; i < arrivalTimes.size(); i++) {
    for (int j = i + 1; j < arrivalTimes.size(); j++) {

      if (arrivalTimes.get(j) < arrivalTimes.get(i)) {

        float tempTime = arrivalTimes.get(i);
        arrivalTimes.set(i, arrivalTimes.get(j));
        arrivalTimes.set(j, tempTime);

        String tempStation = stationNames.get(i);
        stationNames.set(i, stationNames.get(j));
        stationNames.set(j, tempStation);
      }
    }
  }

  sketchStartTime = millis();

  println("Selected train: " + selectedTrain);
  println("Predicted stops: " + stationNames.size());
}

void draw() {
  background(25, 30, 40);

  float elapsedSeconds = (millis() - sketchStartTime) / 1000.0;

  fill(255);
  textSize(24);
  text("Victoria Line Train Visualisation", 30, 40);

  textSize(14);
  fill(190);
  text("Train ID: " + selectedTrain, 30, 70);
  text("Predicted journey from TfL arrival data", 30, 95);

  // Draw railway line
  stroke(0, 152, 212);
  strokeWeight(6);
  line(
    trackX,
    startY,
    trackX,
    startY + (victoriaStations.length - 1) * spacing
  );

  // Draw all stations
  for (int i = 0; i < victoriaStations.length; i++) {
    float stationY = startY + i * spacing;

    stroke(255);
    strokeWeight(2);
    fill(25, 30, 40);
    ellipse(trackX, stationY, 12, 12);

    fill(255);
    textSize(13);
    text(victoriaStations[i], trackX + 25, stationY + 5);
  }

  // Find the next predicted station
  int nextStation = 0;

  while (nextStation < arrivalTimes.size() &&
         arrivalTimes.get(nextStation) <= elapsedSeconds) {
    nextStation++;
  }

  // Calculate train position
  if (stationNames.size() > 0) {

    float trainY;

    if (nextStation == 0) {

      // Start halfway between the previous station and first predicted stop
      int firstStationIndex = getStationIndex(stationNames.get(0));

      float firstStationY = startY + firstStationIndex * spacing;
      float previousStationY = firstStationY - spacing * 0.5;

      float firstArrivalTime = max(1, arrivalTimes.get(0));

      float progress = constrain(
        elapsedSeconds / firstArrivalTime,
        0,
        1
      );

      trainY = lerp(previousStationY, firstStationY, progress);

    } else if (nextStation >= stationNames.size()) {

      // Final predicted station reached
      int index = getStationIndex(
        stationNames.get(stationNames.size() - 1)
      );

      trainY = startY + index * spacing;

    } else {

      // Move between consecutive predicted stations
      int previousIndex = getStationIndex(
        stationNames.get(nextStation - 1)
      );

      int nextIndex = getStationIndex(
        stationNames.get(nextStation)
      );

      float previousTime = arrivalTimes.get(nextStation - 1);
      float nextTime = arrivalTimes.get(nextStation);

      float duration = max(1, nextTime - previousTime);

      float progress = constrain(
        (elapsedSeconds - previousTime) / duration,
        0,
        1
      );

      float previousY = startY + previousIndex * spacing;
      float nextY = startY + nextIndex * spacing;

      trainY = lerp(previousY, nextY, progress);
    }

    // Draw train
    fill(255, 190, 50);
    noStroke();
    ellipse(trackX, trainY, 22, 22);
  }

  // Display next predicted arrival
  fill(255);
  textSize(14);

  if (nextStation < stationNames.size()) {

    float remainingTime = max(
      0,
      arrivalTimes.get(nextStation) - elapsedSeconds
    );

    text(
      "Next predicted stop: " + stationNames.get(nextStation),
      450, 100
    );

    text(
      "Predicted arrival in: " + int(remainingTime) + " seconds",
      450, 125
    );

  } else {
    text("Final predicted stop reached", 450, 100);
  }

  fill(170);
  textSize(12);
  text(
    "Based on TfL arrival predictions. Train position is illustrative.",
    30, 665
  );
}

// Find station position on the Victoria line
int getStationIndex(String station) {
  for (int i = 0; i < victoriaStations.length; i++) {

    if (station.equals(
      victoriaStations[i] + " Underground Station"
    )) {
      return i;
    }
  }

  return 0;
}
