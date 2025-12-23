import pygame
import sys
import asyncio
from constants import SCREEN_WIDTH, SCREEN_HEIGHT
from logger import log_state, log_event
from player import Player
from asteroid import Asteroid
from asteroidfield import AsteroidField
from shot import Shot


async def main():
    print(f"Starting Asteroids with pygame version: {pygame.__version__}")
    print(f"Screen width: {SCREEN_WIDTH}")
    print(f"Screen height: {SCREEN_HEIGHT}")
    pygame.init()

    # Initialize Fonts
    font = pygame.font.Font(None, 64)
    small_font = pygame.font.Font(None, 32)

    screen = pygame.display.set_mode((SCREEN_WIDTH, SCREEN_HEIGHT))
    clock = pygame.time.Clock()
    dt = 0

    # Create Groups
    updatable = pygame.sprite.Group()
    drawable = pygame.sprite.Group()
    asteroids = pygame.sprite.Group()
    shots = pygame.sprite.Group()

    # Set Static Containers
    Player.containers = (updatable, drawable)
    Asteroid.containers = (asteroids, updatable, drawable)
    AsteroidField.containers = updatable
    Shot.containers = (shots, updatable, drawable)

    # Initialize Game Objects
    player = Player(SCREEN_WIDTH / 2, SCREEN_HEIGHT / 2)
    asteroid_field = AsteroidField()

    game_over = False

    while True:
        log_state()
        for event in pygame.event.get():
            if event.type == pygame.QUIT:
                return

            # Restart Logic
            if game_over and event.type == pygame.KEYDOWN and event.key == pygame.K_r:
                game_over = False
                # 1. Clear all groups
                updatable.empty()
                drawable.empty()
                asteroids.empty()
                shots.empty()
                # 2. Re-create player and field (they auto-add to groups)
                player = Player(SCREEN_WIDTH / 2, SCREEN_HEIGHT / 2)
                asteroid_field = AsteroidField()

        screen.fill("black")

        if not game_over:
            # Only update positions if game is running
            updatable.update(dt)

            # Check Collisions
            for asteroid in asteroids:
                for shot in shots:
                    if shot.collides_with(asteroid):
                        log_event("asteroid_shot")
                        shot.kill()
                        asteroid.split()
                if asteroid.collides_with(player):
                    log_event("player_hit")
                    print("Game over!")
                    game_over = True  # Switch state instead of exiting

        # Always draw the game objects (even if game over, so we see the wreckage)
        for sprite in drawable:
            sprite.draw(screen)

        # Draw Game Over Text
        if game_over:
            # 1. Render "Game Over"
            text_surf = font.render("GAME OVER", True, (255, 0, 0))
            text_rect = text_surf.get_rect(
                center=(SCREEN_WIDTH / 2, SCREEN_HEIGHT / 2 - 50)
            )
            screen.blit(text_surf, text_rect)

            # 2. Render "Restart" instruction
            restart_surf = small_font.render(
                "Press 'R' to Restart", True, (255, 255, 255)
            )
            restart_rect = restart_surf.get_rect(
                center=(SCREEN_WIDTH / 2, SCREEN_HEIGHT / 2 + 20)
            )
            screen.blit(restart_surf, restart_rect)

        pygame.display.flip()
        dt = clock.tick(60) / 1000

        await asyncio.sleep(0)


if __name__ == "__main__":
    asyncio.run(main())
