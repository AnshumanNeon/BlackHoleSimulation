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
  int iTime = GetShaderLocation(shader, "iTime");
  int iMouse = GetShaderLocation(shader, "iMouse");
  int iResolution = GetShaderLocation(shader, "iResolution");

  float res[3] = {screenWidth, screenHeight, 1.0f};

  SetTargetFPS(60);

  while (!WindowShouldClose()) {
    float t = GetTime();
    Vector2 mouse = GetMousePosition();
    float m[4] = {0.0f, 0.0f, 0.0f, 0.0f};
    m[0] = mouse.x;
    m[1] = (float)screenHeight - mouse.y;
    if (IsMouseButtonDown(MOUSE_BUTTON_LEFT)) {
      m[2] = mouse.x;
      m[3] = (float)screenHeight - mouse.y;
    }
    
    // Update
    SetShaderValue(shader, iResolution, res, SHADER_UNIFORM_VEC3);
    SetShaderValue(shader, iTime, &t, SHADER_UNIFORM_FLOAT);
    SetShaderValue(shader, iMouse, m, SHADER_UNIFORM_VEC4);
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
