import pygame
from circleshape import CircleShape
from constants import LINE_WIDTH


class Asteroid(CircleShape):
    def __init__(self, x, y, radius):
        super().__init__(x, y, radius)

    def draw(self, screen):
        center = self.position
        radius = self.radius
        pygame.draw.circle(screen, "white", center, radius, LINE_WIDTH)

    def update(self, dt):
        self.position = self.position + (self.velocity * dt)
