# Simulator demonstration

[Play the complete MarketPulse demo](MarketPulse-full-demo-2026-10-29.mp4)

Recorded on 2026-10-29 using the normal Release application on iPhone 17 Pro / iOS 26.5. This is a continuous, unedited simulator capture, with no narration or audio. Duration: 3 minutes 31.56 seconds. Format: H.264 MP4, 1206 × 2622 pixels.

The app uses the real `wss://ws.postman-echo.com/raw` connection. All prices remain simulated; no UI test transport or launch arguments were used.

Approximate chapters:

- 00:00 — Light watchlist, seeded prices, Start and successful connection.
- 00:20 — Live price changes; sort by percentage movement and price in both directions.
- 01:05 — Scroll through the stock catalog and received-echo counter.
- 01:48 — Coca-Cola details, shared quote, received history and company description.
- 02:10 — System appearance changes to dark while the feed remains connected.
- 02:32 — Stop preserves the last quote; Start reconnects.
- 02:43 — Return to the dark watchlist and stop the feed at the end.

Verification: AVFoundation successfully decoded eight frames across the recording, including the beginning and end. Representative frames were visually inspected for the watchlist, live quote updates, dark details/history, and final stopped state. This video covers the phone portrait flow; it is not evidence of Duo poses, landscape, or expanded layouts. The simulator was left running with the feed stopped and light appearance restored.
