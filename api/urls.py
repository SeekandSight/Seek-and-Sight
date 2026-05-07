from django.urls import path
from . import views

urlpatterns = [
    path('tim/ai-response/', views.ai_response, name='ai_response'),
]
