import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_router.g.dart';

@riverpod
GoRouter appRouter(Ref ref) {
  return GoRouter(
    redirect: (context, state) {
      // TODO: 인증 feature의 상태를 여기서 읽고, 공개/보호 경로를 판정한다.
      // app은 합성 루트이므로 feature import가 허용되는 유일한 자리다.
      return null;
    },
    routes: <RouteBase>[
      // PRD의 기능 화면을 만든 뒤 GoRoute를 이 배열에 추가한다.
    ],
  );
}
