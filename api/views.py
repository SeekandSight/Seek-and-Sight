from rest_framework.decorators import api_view
from rest_framework.response import Response

@api_view(['POST'])
def ai_response(request):
    user_message = request.data.get('message', 'No message received')

    return Response({
        "reply": f"Techie Tim heard: '{user_message}'! (AI logic coming soon)"
    })