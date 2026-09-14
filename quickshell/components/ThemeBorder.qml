import QtQuick
import QtQuick.Shapes
Shape {
    id: frame
    anchors.fill: parent
    property color lineColor: Theme.accent
    property int lineWidth: Theme.borderWidth
    property string lineStyle: Theme.borderStyle
    property real cornerRadius: Theme.borderRadius
    visible: lineStyle !== "none" && lineWidth > 0
    ShapePath {
        fillColor: "transparent"
        strokeColor: frame.lineStyle === "none" ? "transparent" : frame.lineColor
        strokeWidth: frame.lineWidth
        strokeStyle: frame.lineStyle === "solid" ? ShapePath.SolidLine : ShapePath.DashLine
        dashPattern: frame.lineStyle === "dotted" ? [1,2] : [4,2]
        capStyle: frame.lineStyle === "dotted" ? ShapePath.RoundCap : ShapePath.FlatCap
        PathSvg {
            path: {
                var x = frame.lineWidth / 2, y = x
                var w = Math.max(0,frame.width-frame.lineWidth), h = Math.max(0,frame.height-frame.lineWidth)
                var r = Math.min(frame.cornerRadius,w/2,h/2)
                return "M "+(x+r)+" "+y+" H "+(x+w-r)+" Q "+(x+w)+" "+y+" "+(x+w)+" "+(y+r)
                    +" V "+(y+h-r)+" Q "+(x+w)+" "+(y+h)+" "+(x+w-r)+" "+(y+h)
                    +" H "+(x+r)+" Q "+x+" "+(y+h)+" "+x+" "+(y+h-r)
                    +" V "+(y+r)+" Q "+x+" "+y+" "+(x+r)+" "+y+" Z"
            }
        }
    }
}
