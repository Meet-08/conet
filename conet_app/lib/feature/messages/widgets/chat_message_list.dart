import 'package:conet_app/feature/messages/widgets/chat_message_bubble.dart';
import 'package:flutter/material.dart';

class ChatMessageList extends StatelessWidget {
  const ChatMessageList({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: const [
        ChatMessageBubble(
          text:
              "It's going great! Just finished implementing the neural network. "
              "The accuracy is around 85% now.",
          time: '02:34 PM',
          isMe: true,
        ),
        ChatMessageBubble(
          text:
              "That's awesome! Would love to see the code sometime. "
              "Are you using TensorFlow or PyTorch?",
          time: '03:04 PM',
          isMe: false,
        ),
        ChatMessageBubble(
          text:
              "I'm using PyTorch. The documentation is really good and "
              "it's quite intuitive. I can share the GitHub repo with you!",
          time: '03:34 PM',
          isMe: true,
        ),
        ChatMessageBubble(
          text:
              "Perfect! Also, did you check out the ML workshop I shared yesterday?",
          time: '03:49 PM',
          isMe: false,
        ),
        ChatMessageBubble(
          text:
              "Yes! Already registered. Thanks for sharing. "
              "The topics look really interesting, especially the computer vision part.",
          time: '03:59 PM',
          isMe: true,
        ),
      ],
    );
  }
}
