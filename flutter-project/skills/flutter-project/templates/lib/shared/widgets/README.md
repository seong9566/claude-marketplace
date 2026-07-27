# 공용 UI 위젯

여러 기능이 함께 쓰는 UI 위젯의 유일한 자리다. `shared/value_objects/`와 `shared/entities/`는 순수 Dart를 유지하며, Flutter import 예외는 `shared/widgets/` 하위에만 적용한다.

- 둘 이상 기능이 실제로 쓰는 표현 전용 위젯만 둔다. 한 기능만 쓰면 해당 기능의 `presentation/widgets/`에 둔다.
- 특정 기능의 도메인을 알거나 ViewModel·Repository를 직접 호출하는 위젯은 두지 않는다.
- 공유 상태는 위젯에 두지 않고 이음매 ①(core 슬롯) 또는 ②(app 합성)로 푼다(§3).
