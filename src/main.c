#include "raylib.h"

int main() {
  const int screenWidth = 800;
  const int screenHeight = 450;

  InitWindow(screenWidth, screenHeight, "Black Hole Simulation");

  Texture tex = LoadTexture("stars.png");
  SetTextureWrap(tex, TEXTURE_WRAP_REPEAT);
  SetTextureFilter(tex, TEXTURE_FILTER_BILINEAR);

  Shader shader = LoadShader(0, TextFormat("shaders/black_hole.glsl"));

  int iChannel0 = GetShaderLocation(shader, "iChannel0");

  SetTargetFPS(60);

  while (!WindowShouldClose()) {
    // Update
    SetShaderValueTexture(shader, iChannel0, tex);

    // Draw
    BeginDrawing();
    ClearBackground(RAYWHITE);

    BeginShaderMode(shader);
    DrawRectangle(0, 0, screenWidth, screenHeight, WHITE);
    EndShaderMode();
    
    EndDrawing();
  }

  // De-Initialization
  UnloadShader(shader);
  UnloadTexture(tex);
  CloseWindow();

  return 0;
}
