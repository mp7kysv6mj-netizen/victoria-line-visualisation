
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.StandardOpenOption;
import java.time.Instant;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;

public class VictoriaLineCollector {

    private static final String API_URL =
            "https://api.tfl.gov.uk/Line/victoria/Arrivals";

    private static final Path CSV_FILE =
            Path.of("data", "victoria_line_observations.csv");

    private static final int INTERVAL_SECONDS = 60;
    private static final int DURATION_MINUTES = 30;

    public static void main(String[] args) {

        HttpClient client = HttpClient.newHttpClient();
        ObjectMapper mapper = new ObjectMapper();

        long endTime = System.nanoTime()
                + DURATION_MINUTES * 60L * 1_000_000_000L;

        int totalObservations = 0;
        int snapshots = 0;

        try {
            Files.createDirectories(CSV_FILE.getParent());

            while (System.nanoTime() < endTime) {

                System.out.println("\nCollecting TfL data...");

                HttpRequest request = HttpRequest.newBuilder()
                        .uri(URI.create(API_URL))
                        .GET()
                        .build();

                HttpResponse<String> response = client.send(
                        request,
                        HttpResponse.BodyHandlers.ofString()
                );

                if (response.statusCode() == 200) {

                    JsonNode arrivals = mapper.readTree(response.body());

                    // One timestamp for this entire API snapshot
                    String capturedAt = Instant.now().toString();

                    boolean writeHeader =
                            !Files.exists(CSV_FILE)
                                    || Files.size(CSV_FILE) == 0;

                    try (var writer = Files.newBufferedWriter(
                            CSV_FILE,
                            StandardOpenOption.CREATE,
                            StandardOpenOption.APPEND)) {

                        if (writeHeader) {
                            writer.write("capturedAt,vehicleId,stationName,"
                                    + "platformName,direction,destinationName,"
                                    + "timeToStation,expectedArrival");
                            writer.newLine();
                        }

                        for (JsonNode train : arrivals) {

                            String row = String.join(",",
                                    csv(capturedAt),
                                    csv(train.path("vehicleId").asText()),
                                    csv(train.path("stationName").asText()),
                                    csv(train.path("platformName").asText()),
                                    csv(train.path("direction").asText()),
                                    csv(train.path("destinationName").asText()),
                                    csv(train.path("timeToStation").asText()),
                                    csv(train.path("expectedArrival").asText())
                            );

                            writer.write(row);
                            writer.newLine();

                            totalObservations++;
                        }
                    }

                    snapshots++;

                    System.out.println("Snapshot: " + snapshots);
                    System.out.println("Predictions this snapshot: "
                            + arrivals.size());
                    System.out.println("Total observations: "
                            + totalObservations);

                } else {
                    System.out.println("TfL returned status: "
                            + response.statusCode());
                }

                // Wait 60 seconds before the next request
                if (System.nanoTime() < endTime) {
                    Thread.sleep(INTERVAL_SECONDS * 1000L);
                }
            }

            System.out.println("\nCollection finished!");
            System.out.println("Snapshots collected: " + snapshots);
            System.out.println("Total observations: " + totalObservations);
            System.out.println("Saved to: " + CSV_FILE);

        } catch (IOException | InterruptedException e) {
            e.printStackTrace();
        }
    }

    private static String csv(String value) {
        return "\"" + value.replace("\"", "\"\"") + "\"";
    }
}
