from django.contrib import admin
from django.urls import path, include  # <-- ADD 'include' HERE

urlpatterns = [
    path('admin/', admin.site.urls),
    path('api/', include('api.urls')),  # <-- ADD THIS LINE
]
