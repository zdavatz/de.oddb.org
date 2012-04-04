=begin
= class Quanty

== ����

���� (ʪ����)�פȡ�ñ�̡פ�ʻ�����ĥ��饹��
((%units%)) ���ޥ�ɤΤ褦��ñ���Ѵ���ǽ��¾��
((*km*)) �� ((*mile*)) �ʤɡ��ۤʤ�ñ�̤�����̤α黻���ǽ��

== ��

  require 'quanty'
  Quanty(1.23,'km') + Quanty(4.56,'m')    #=> Quanty(1.23456,'km')
  Quanty(123,'mile') / Quanty(2,'hr')     #=> Quanty(61,'mile / hr')
  Quanty(61,'miles/hr').want('m/s')       #=> Quanty(27.26944,'m/s')
  Quanty(1.0,'are') == Quanty(10,'m')**2  #=> true
  Math.cos(Quanty(60,'degree'))           #=> 0.5

== Quanty ���饹

=== �����ѡ����饹:
    �Ȥꤢ���� Object��(Numeric�Τۤ����褤����)

=== ���饹�᥽�å�:
--- Quanty.new([value],[unit])
--- Quanty([value],[unit])
�̤��ͤ�((|value|))��ñ�̤�((|unit|)) (ʸ����)�Ȥ���
Unit ���饹�Υ��󥹥��󥹤��������롣
((|value|))����ά���줿���ϡ�1�����ꤵ�줿����Ʊ����
((|unit|))����ά���줿���ϡ�""�����ꤵ�줿����Ʊ���ǡ�ñ�̤ʤ��̤ˤʤ롣
ñ�̤ν����ϡ�����((<ñ��ɽ��ˡ>))�򻲾ȡ�

=== �᥽�å�:
--- self + other
--- self - other
�̤βû���������
((|other|))��ñ�̤�((|self|))��ñ�̤��Ѵ����Ʊ黻���롣
ñ���Ѵ����Ǥ��ʤ�����㳰��ȯ�����롣
��̤�((|self|))��ñ�̤ˤ��� Quanty ���饹�Υ��󥹥��󥹤��֤���

--- self * other
�̤ξ軻��
��̤�ñ�̤ϡ�((|self|))��((|other|))��ñ�̤�Ϣ�뤷�ƺ�롣

--- self / other
�̤ν�����
��̤�ñ�̤ϡ�
((|self|))��((|other|))��ñ�̤�(({"/"}))��Ϥ����Ϣ�뤷�ƺ�롣

--- self ** number
�̤��Ѿ衣
��̤�ñ�̤ϡ�"(((|self|))��ñ��)^((|number|))" �Ȥ��ƺ�롣

--- self == other
--- self < other
--- self <= other
--- self > other
--- self >= other
�̤���ӡ�

--- coerce(number)
((|number|))��ñ�̤ʤ�Quanty���饹�Υ��󥹥��󥹤ˤ���
[((|number|)),((|self|))]�Ȥ����֤���

--- to_si
--- to_SI
((|self|))��SIñ�̷Ϥ��Ѵ����롣

--- to_f
((|self|))��ñ�̤ʤ��̤ξ��ϡ����Ȥ��ͤ��֤���
((|self|))�����٤ξ��ϡ�radian���Ѵ������ͤ��֤���
����ʳ���ñ�̤ξ��ϡ��㳰��ȯ�����롣

--- unit
ñ�̤�ʸ������֤���

--- val
--- value
�̤��ͤ��֤���

--- want(unit)
((|self|))�� ((|unit|)) (ʸ����) ��ñ�̤Ȥ����̤��Ѵ����롣


== ñ��ɽ��ˡ

==== ��ˡ
 'N m' == 'N*m'

==== ��ˡ
 '/s' , 'm/s'

==== �٤�
 'm-2' == 'm^-2' == 'm**-2'

==== ������
 '12 inch' == 'feet'

==== ����
 'm/s*m' == 'm^2/s'.
 'm/(s*m)' ==  '/s'.

+ �ܺ٤� ((%parse.y%)) �򻲾ȤΤ��ȡ�

== Author
((<Masahiro Tanaka|URL:http://www.ir.isas.ac.jp/~masa/index-e.html>))
(2001-04-25)
=end
