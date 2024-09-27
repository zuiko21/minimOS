'use strict'

let width, canvasData, ctx, state

let red = new Array(0, 0, 0xFF, 0xFF, 0, 0, 0xFF, 0xFF, 0, 0, 0xFF, 0xFF, 0, 0, 0xFF, 0xFF)
let green = new Array(0, 0xAA, 0, 0xAA, 0x55, 0xFF, 0x55, 0xFF, 0, 0xAA, 0, 0xAA, 0x55, 0xFF, 0x55, 0xFF)
let blue = new Array (0, 0, 0, 0, 0, 0, 0, 0, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF)

window.onload = () => {
	initSeed()
	runGenerator()
	document.getElementById('run').onclick = () => runGenerator()
}

function runGenerator() {
	const canvas = document.getElementById('canvas')
	width = canvas.width
	const height = canvas.height
	ctx = canvas.getContext('2d')
	canvasData = ctx.getImageData(0, 0, width, height)
	ctx.clearRect(0, 0, width, height)
	ctx.putImageData(canvasData, 0, 0)
	generateAll(width, height)
}

function initSeed() {
	state = Math.floor(Math.random() << 16)
}

function generateAll(width, height) {
	const multiplier = getParameter('multiplier')
	const addition = getParameter('addition')
	for (let i=0; i<256; i++) {
		for (let j=0; j<256; j++) {
			let x=generate(multiplier, addition)>>1
			let y=generate(multiplier, addition)>>1
			let colour=generate(multiplier, addition)&15
			drawFat(x, y, colour)
		}
	}
	updateCanvas()
}

function generate(multiplier, addition) {
	const temp = state * multiplier + addition
	state = temp & 65535
	return Math.floor(state>>8)
}

function getParameter(name) {
	return parseFloat(document.getElementById(name).value)
}

function drawFat (x, y, c) {
	let r=red[c]
	let g=green[c]
	let b=blue[c]
	drawPixel(x<<1, y<<1, r, g, b, 255)
	drawPixel(1+(x<<1), y<<1, r, g, b, 255)
	drawPixel(x<<1, 1+(y<<1), r, g, b, 255)
	drawPixel(1+(x<<1), 1+(y<<1), r, g, b, 255)
}

function drawPixel (x, y, r, g, b, a) {
	var index = (x + y * width) << 2

	canvasData.data[index] = r
	canvasData.data[index + 1] = g
	canvasData.data[index + 2] = b
	canvasData.data[index + 3] = a
}

function updateCanvas() {
	ctx.putImageData(canvasData, 0, 0)
}

